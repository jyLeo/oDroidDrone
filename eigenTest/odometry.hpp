#ifndef _ODOMETRY_H_
#define _ODOMETRY_H_

#include <Eigen/Dense>
#include <Eigen/Geometry>
#include <stdbool.h>

using namespace Eigen;

class Calib {
public:
	// 
	// Camera calibration
	//
	/* Projection */
	double o_x, o_y,  // principal point [px,px]
			f_x, f_y, // focal length [px,px]
			k1, k2,   // radial distortion parameters [n/u,n/u]
			t1, t2;   // tangential distortion parameters [n/u,n/u]
	/* Position */
	Quaternion<double> CI_q; // Rotation from intertial to camera coordinates. [unit quaternion]
	Vector3d C_p_I;              // Position of inertial frame in camera coordinates [m,m,m]
	//
	// Physical properties
	//
	double g;           // Gravitational acceleration [m/s^2]
	double delta_t;     // Time between IMU data [s]
	double imageOffset; // Time delay for images [s]
	//
	// Noise levels
	//
	/* IMU TODO: add correct units */
	double sigma_gc, sigma_ac,    // Standard deviation of IMU noise [rad/s, m/s^2]
			sigma_wgc, sigma_wac; // Standard deviation of IMU random walk noise [rad/s, m/s^2]
	/* Camera */
	double sigma_Im; // Image noise
	/* distance sensor */
	double sigma_dc; // Standard deviation of distance sensor noise [m]
	//
	// Options
	//
	unsigned int maxFrame; // Maximum frames in FIFO

	Calib( );
	friend std::ostream& operator<<( std::ostream& out, const Calib& calib );
};


class MSCKF {
	//
	// Calibration object
	//
	Calib* calib;
	//
	// State
	//
	VectorXd x;
	//
	// Covariance
	//
	MatrixXd sigma;
	//
	// Local variables for integration
	//
	Vector3d I_a_dly, I_g_dly;

public:
	// print
	friend std::ostream& operator<<( std::ostream& out, const MSCKF& msckf );
	// init
	MSCKF( Calib* cal );
	// propagate
	// 	Propagate state
	void propagateState( double a_m[3], double g_m[3] );
	// 	Propagate sigma
	// updateCamera
	// 	triangluate
	// -marginalize
	//  ETC
	// updateDist
};


#endif //_ODOMETRY_H_