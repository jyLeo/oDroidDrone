%% set calib file
calib.o_x = 300.8859;
calib.o_y = 222.5206;
calib.f_x = 411.1170;
calib.f_y = 409.9516;
calib.k1 = -0.3453;
calib.k2 = 0.1012;
calib.k3 = 0;
calib.t1 = -0.0003;
calib.t2 = 0.0014;

calib.CI_q = axisAngle2quatern( [0,1,-1], pi)'; % rotation from inertial frame to camera
calib.CI_q = quaternProd( calib.CI_q',...
    axisAngle2quatern( [1,0,0], -pi/4)...
    )';
calib.C_p_I = [0, 0.0, -0.056]';%position of camera in inertial frame

calib.g = 9.82;
calib.Delta_t = 1/400;
calib.sigma_gd = 0.01;
calib.sigma_ad = 0.01;
calib.sigma_wgd = 0.05 * sqrt( calib.Delta_t );
calib.sigma_wad = 0.1 * sqrt( calib.Delta_t );

calib.sigma_gc = calib.sigma_gd * sqrt( calib.Delta_t );
calib.sigma_ac = calib.sigma_ad * sqrt( calib.Delta_t );
calib.sigma_wgc = calib.sigma_wgd / sqrt( calib.Delta_t );
calib.sigma_wac = calib.sigma_wad / sqrt( calib.Delta_t );

calib.sigma_dc = 0.05;

calib.sigma_Im = 40;

calib.crop_x1 = 0;
calib.crop_x2 = 640;
calib.crop_y1 = 0;
calib.crop_y2 = 480;

calib.maxFrame = 5;

calib.imageOffset = 0.033; %delay of camera with respect to imu in s


x_Ci = [ [ 0, 1, 0, 0 ] [ 0, 0, 0.90 ] [ 0, 0, 0 ] ]';


z = [320;240];
[ G_p_f, f, J_h, theta_log, G_p_f_log ] = triangulate( z, x_Ci, calib );
G_p_f = G_p_f

z = [0;0];
[ G_p_f, f, J_h, theta_log, G_p_f_log ] = triangulate( z, x_Ci, calib );
G_p_f = G_p_f

z = [640;0];
[ G_p_f, f, J_h, theta_log, G_p_f_log ] = triangulate( z, x_Ci, calib );
G_p_f = G_p_f

z = [0;480];
[ G_p_f, f, J_h, theta_log, G_p_f_log ] = triangulate( z, x_Ci, calib );
G_p_f = G_p_f

z = [640;480];
[ G_p_f, f, J_h, theta_log, G_p_f_log ] = triangulate( z, x_Ci, calib );
G_p_f = G_p_f



format long % loose as litte precission as possible
%% Test marignalize and update
load( 'testVars.mat' )

z = z(:,z_lost);
z_length = z_length(:,z_lost);

z = z(:,z_length>=3);
z_length = z_length(:,z_length>=3);

[ IG_q, G_p, G_v, b_g, b_a, x_C ] = unpackState( x );
delete 'matlabTest.h'
file = fopen('matlabTest.h','w');
printMatlabVarAsEigen( file, 'MatrixXd', 'x', x );
printMatlabVarAsEigen( file, 'MatrixXd', 'sigma', Sigma );
fprintf( file, 'msckf.x = x;\n' );
fprintf( file, 'msckf.sigma = sigma;\n' );


for j=1:2
    [ r_0j, H_0j, G_p_fj, clearOutlier ] = marginalize( z(:,j), x_C, z_length(j), calib );
    
    z_ = z( end+1-2-z_length(j)*2:end-2, j );
    z_ = reshape( z_', 2, z_length(j) )';
    fprintf( file, '{\n' );
    
    printMatlabVarAsEigen( file, 'MatrixX2d', 'z', z_ );
    printMatlabVarAsEigen( file, 'MatrixXd', 'G_p_f', G_p_fj );
    printMatlabVarAsEigen( file, 'MatrixXd', 'r0_matlab', r_0j );
    printMatlabVarAsEigen( file, 'MatrixXd', 'H0_matlab', H_0j );
    fprintf( file, [...
        'VectorXd r0 = VectorXd( z.rows()*2-3 );\n'...
        'MatrixXd H0 = MatrixXd( z.rows()*2-3, sigma.cols() );\n'...
        'msckf.marginalize( z, G_p_f, r0, H0 );\n'...
        'std::cout << "r0: " << r0 - r0_matlab << std::endl;\n'...
        'std::cout << "H=: " << H0 - H0_matlab << std::endl;\n'...
        '}\n'...
        ] );
end

%% test append state
fprintf( file, '{\n' );
fprintf( file, 'msckf.x = x;\n' );
fprintf( file, 'msckf.sigma = sigma;\n' );
[ x_, Sigma_ ] = augment( x, Sigma, calib );
printMatlabVarAsEigen( file, 'MatrixXd', 'x_', x_ );
printMatlabVarAsEigen( file, 'MatrixXd', 'Sigma_', Sigma_ );
fprintf( file, 'msckf.augmentState();\n' );
fprintf( file, [...
    'std::cout << "x: " << msckf.x - x_ << std::endl;\n'...
    'std::cout << "sigma: " << msckf.sigma - Sigma_ << std::endl;\n'...
    '}\n'...
    ] );

%% test propagate
fprintf( file, '{\n' );
fprintf( file, 'msckf.x = x;\n' );
fprintf( file, 'msckf.sigma = sigma;\n' );
fprintf( file,[ ...
    'double acc[3] = { 0, 0, -9.82 };\n'...
    'double gyro[3]= { 0, 0.001, 0 };\n'...
    'msckf.I_a_dly(0) = 0; msckf.I_a_dly(1) = 0; msckf.I_a_dly(2) = -9.82;\n'...
    'msckf.I_g_dly(0) = 0; msckf.I_g_dly(1) = 0; msckf.I_g_dly(2) = 0;\n'...
    ]);
x_ = x;
Sigma_ = Sigma;
[ x_, Sigma_, I_omega, I_a, G_a ] = propagate( x_, Sigma_, [ 0,0.001,0, 0, 0, -9.82]', [0,0,0]', [0,0,-9.82]', calib );
for i=1:399
    [ x_, Sigma_, I_omega, I_a, G_a ] = propagate( x_, Sigma_, [ 0,0.001,0, 0, 0, -9.82]', [0,0.001,0]', [0,0,-9.82]', calib );
end

fprintf( file, 'for(int i=0; i<400; i++) msckf.propagate( acc, gyro );\n' );

printMatlabVarAsEigen( file, 'MatrixXd', 'x_', x_ );
printMatlabVarAsEigen( file, 'MatrixXd', 'Sigma_', Sigma_ );

fprintf( file, [...
    'std::cout << "x: " << msckf.x - x_ << std::endl;\n'...
    'std::cout << "sigma: " << msckf.sigma - Sigma_ << std::endl;\n'...
    '}\n'...
    ] );

fclose(file);
format short