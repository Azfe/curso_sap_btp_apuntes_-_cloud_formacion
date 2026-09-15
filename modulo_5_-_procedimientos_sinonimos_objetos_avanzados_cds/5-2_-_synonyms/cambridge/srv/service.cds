using uni.cambridge as hv from '../db/schema';

@path: 'cambridge-service'
service CambridgeService {
    entity Courses as projection on hv.Course;
    entity Subjects as projection on hv.Subjects;
    entity Students as projection on hv.Students;
    entity Grade_Subject as projection on hv.Grade_Subject;    
}
