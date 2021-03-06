#include <stdio.h>
#include <iostream>
#include "opencv2/opencv.hpp"
#include <Eigen/Dense>
#include <list>
#include "common.hpp"


void CameraMeasurements::addFeatures( const std::vector<cv::KeyPoint> &keypointsOld, const std::vector<cv::KeyPoint> &keypointsNew,
		const std::vector< cv::DMatch >& matches ) {
	std::vector< std::list<CameraMeas_t>::iterator > linkOld = link;


	// Go through all measurements and mark all of them as lost
	for ( std::list<CameraMeas_t>::iterator meas_j = meas.begin(); meas_j != meas.end(); ++meas_j ) {
		meas_j->isLost = true;
	}

	// mark all links as no link
	link.assign( keypointsNew.size(), meas.end() );

	// Go through all features with a match, add them at the correct place
	for ( int i = 0; i < matches.size(); i++ ) if ( matches[i].distance < 30 ) {
		// Check if this feature is in meas
		if ( linkOld[matches[i].queryIdx] != meas.end() ) {
			//
			// Feature is already in meas
			//
			// Link it
			link[matches[i].trainIdx] = linkOld[matches[i].queryIdx];
			// Add to feature
			this->addToFeature( link[matches[i].trainIdx],
					keypointsNew[matches[i].trainIdx].pt.x, keypointsNew[matches[i].trainIdx].pt.y );
			// Add link back
			this->linkBack( link[matches[i].trainIdx], matches[i].trainIdx );

		} else {
			//
			// Feature is new. In this case both old and new is to be added
			//

			// Add a new entry and link it
			link[matches[i].trainIdx] = this->addFeature();
			// Add data to it
			addToFeature( link[matches[i].trainIdx],
					keypointsOld[matches[i].queryIdx].pt.x, keypointsOld[matches[i].queryIdx].pt.y );
			addToFeature( link[matches[i].trainIdx],
					keypointsNew[matches[i].trainIdx].pt.x, keypointsNew[matches[i].trainIdx].pt.y );
			// Add link back
			this->linkBack( link[matches[i].trainIdx], matches[i].trainIdx );
		}
	}
}


void CameraMeasurements::linkBack( std::list<CameraMeas_t>::iterator& feature, int linkLink ) {
	feature->linkLink = linkLink;
}

void CameraMeasurements::addToFeature( std::list<CameraMeas_t>::iterator& feature,
		double x, double y ) {
	// Add feature TODO: consider if theis matrix should be made a vector
	Eigen::MatrixX2d& z = feature->z;
	z.conservativeResize ( z.rows() + 1, Eigen::NoChange );
	z.block<1,2>( z.rows()-1, 0 ) <<
			x,
			y;
	// It is no longer lost
	feature->isLost = false;
}

std::list<CameraMeas_t>::iterator CameraMeasurements::addFeature( ) {
	// Add a new entry
	CameraMeas_t z;
	std::list<CameraMeas_t>::iterator newFeature = meas.insert( meas.begin(), z );
	newFeature->z = Eigen::MatrixX2d( 0, 2 );
	// lost (well empty)
	newFeature->isLost = true;
	// no link back to link yet
	newFeature->linkLink = -1;
	// Return iterator to the new feature
	return newFeature;
}

std::list<CameraMeas_t>::iterator CameraMeasurements::removeFeature( std::list<CameraMeas_t>::iterator& feature ) {
	// If it linked back to link (link links keypoints to meas)
	if( feature->linkLink >= 0 ) {
		link[ feature->linkLink ] = meas.end();
	}
	return meas.erase( feature );
}