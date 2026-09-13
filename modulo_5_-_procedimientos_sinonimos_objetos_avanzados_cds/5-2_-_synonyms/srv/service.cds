using uni.harvard as hv from '../db/schema';

@path: 'harvard-service'
service HarvardService {
    entity Courses as projection on hv.Course;
    entity Signatures as projection on hv.Signatures;
    entity Students as projection on hv.Students;
    entity Grade_Signature as projection on hv.Grade_Signature;
}

