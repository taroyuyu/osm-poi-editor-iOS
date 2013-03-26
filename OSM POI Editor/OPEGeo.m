//
//  OPEGeo.m
//  OSM POI Editor
//
//  Created by David on 3/25/13.
//
//

#import "OPEGeo.h"
#import "proj_api.h"

@implementation OPEGeo

+(double)degreesToRadians:(double)degrees
{
    return degrees * M_PI/180.0;
}
+(double)radiansToDegrees:(double)radians
{
    return radians * 180.0/M_PI;
}

+(double)bearingFrom:(CLLocation *)location1 to:(CLLocation *)location2
{
    double fLat = [OPEGeo degreesToRadians: location1.coordinate.latitude];
    double fLng = [OPEGeo degreesToRadians: location1.coordinate.longitude];
    double tLat = [OPEGeo degreesToRadians: location2.coordinate.latitude];
    double tLng = [OPEGeo degreesToRadians: location2.coordinate.longitude];
    
    return atan2(sin(fLng-tLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(fLng-tLng));
}

+(double)constantBearingFrom:(CLLocation *)location1 to:(CLLocation *)location2
{
    double lat1 = [OPEGeo degreesToRadians: location1.coordinate.latitude];
    double lon1 = [OPEGeo degreesToRadians: location1.coordinate.longitude];
    double lat2 = [OPEGeo degreesToRadians: location2.coordinate.latitude];
    double lon2 = [OPEGeo degreesToRadians: location2.coordinate.longitude];
    
    //double dLat = lat2-lat1;
    double dLon = lon2-lon1;
    
    double dPhi = log(tan(M_PI/4+lat2/2)/tan(M_PI/4+lat1/2));
    //double q = (isfinite(dLat/dPhi)) ? dLat/dPhi : cos(lat1);  // E-W line gives dPhi=0
    
    // if dLon over 180° take shorter rhumb across anti-meridian:
    if (abs(dLon) > M_PI) {
        dLon = dLon>0 ? -(2*M_PI-dLon) : (2*M_PI+dLon);
    }
    
    //var d = Math.sqrt(dLat*dLat + q*q*dLon*dLon) * R;
    double brng = atan2(dLon, dPhi);
    return brng;
}

+ (OPEProjectedPoint)coordinateToProjectedPoint:(CLLocationCoordinate2D)aLatLong
{
    projUV uv = {
        aLatLong.longitude * DEG_TO_RAD,
        aLatLong.latitude * DEG_TO_RAD
    };
    
   
    projUV result = pj_fwd(uv,  pj_init_plus([@"+proj=latlong +ellps=WGS84" UTF8String]));
    
    OPEProjectedPoint result_point = {
        result.u,
        result.v,
    };
    
    return result_point;
}
+(CLLocationCoordinate2D)toCoordinate:(OPEProjectedPoint)point
{
    projUV uv = {
        point.x,
        point.y,
    };
    
    projUV result = pj_inv(uv, pj_init_plus([@"+proj=latlong +ellps=WGS84 +units=m" UTF8String]));
    
    CLLocationCoordinate2D result_coordinate = {
        result.v * RAD_TO_DEG,
        result.u * RAD_TO_DEG,
    };
    
    return result_coordinate;
}

+(double)distance:(CLLocationCoordinate2D)point1 to:(CLLocationCoordinate2D)point2
{
    CLLocation * l1 = [[CLLocation alloc] initWithLatitude:point1.latitude longitude:point1.longitude];
    CLLocation * l2 = [[CLLocation alloc] initWithLatitude:point2.latitude longitude:point2.longitude];
    
    return [l1 distanceFromLocation:l2];
}

+(double)distanceFromProjectedPoint:(OPEProjectedPoint)point1 to:(OPEProjectedPoint)point2
{
    return [OPEGeo distance:[OPEGeo toCoordinate:point1] to:[OPEGeo toCoordinate:point2]];
}

+(OPELineSegment)lineSegmentFromPoint:(CLLocationCoordinate2D)point1 toPoint:(CLLocationCoordinate2D)point2
{
    OPELineSegment line ={point1,point2};
    return line;
}

+(OPEProjectedLineSegment)projectedLineFrom:(OPELineSegment)lineSegment
{
    OPEProjectedPoint x = [OPEGeo coordinateToProjectedPoint:lineSegment.x];
    OPEProjectedPoint y = [OPEGeo coordinateToProjectedPoint:lineSegment.y];
    
    OPEProjectedLineSegment pLineSegment = {x,y};
    return pLineSegment;
}

+(double)distanceFrom:(OPEProjectedPoint)point1 to:(OPEProjectedPoint)point2
{
    return sqrt(pow(point2.x-point1.x,2)+pow(point2.y-point1.y, 2));
}
+(double)distanceSquaredFrom:(OPEProjectedPoint)point1 to:(OPEProjectedPoint)point2
{
    return pow(point2.x-point1.x,2)+pow(point2.y-point1.y, 2);
}

+(double)dot:(OPEProjectedPoint)point1 and:(OPEProjectedPoint)point2
{
    return (point1.x*point2.x+point2.y*point2.y);
}

+ (double)distanceFromlineSegment:(OPELineSegment)lineSegment toPoint:(CLLocationCoordinate2D)point
{
    OPEProjectedLineSegment pLineSegment = [OPEGeo projectedLineFrom:lineSegment];
    OPEProjectedPoint pPoint = [OPEGeo coordinateToProjectedPoint:point];
    OPEProjectedPoint v = pLineSegment.x;
    OPEProjectedPoint w = pLineSegment.y;
    double l2 = [OPEGeo distanceSquaredFrom:pLineSegment.x to:pLineSegment.y];
    if (l2 == 0.0) {
        return [OPEGeo distanceFrom:pLineSegment.x to:pPoint];
    }
    
    OPEProjectedPoint p1 = {pPoint.x-pLineSegment.x.x,pPoint.x-pLineSegment.x.y};
    OPEProjectedPoint p2 = {pLineSegment.y.x-pLineSegment.x.x,pLineSegment.y.y -pLineSegment.x.y};
    
    double t = [OPEGeo dot:p1 and:p2]/l2;
    if (t < 0.0) {
        return [OPEGeo distanceFromProjectedPoint:pPoint to:pLineSegment.x];
    }
    else if (t > 1.0) {
        return [OPEGeo distanceFromProjectedPoint:pPoint to:pLineSegment.y];
    }
    else {
        OPEProjectedPoint p3 = {(w.x-v.x)*t+v.x,(w.y-v.y)*t+v.y};
        double dist = [OPEGeo distanceFromProjectedPoint:pPoint to:p3];
        return dist;
    }
}

/*
float minimum_distance(vec2 v, vec2 w, vec2 p) {
    // Return minimum distance between line segment vw and point p
    const float l2 = length_squared(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
    if (l2 == 0.0) return distance(p, v);   // v == w case
    // Consider the line extending the segment, parameterized as v + t (w - v).
    // We find projection of point p onto the line.
    // It falls where t = [(p-v) . (w-v)] / |w-v|^2
    const float t = dot(p - v, w - v) / l2;
    if (t < 0.0) return distance(p, v);       // Beyond the 'v' end of the segment
    else if (t > 1.0) return distance(p, w);  // Beyond the 'w' end of the segment
    const vec2 projection = v + t * (w - v);  // Projection falls on the segment
    return distance(p, projection);
}
 */

@end