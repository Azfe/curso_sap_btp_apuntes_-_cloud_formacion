using uni.cambridge as hv from '../db/schema';
using {
    HARVARD_STUDENTS,
    HARVARD_SUBJECTS,
    HARVARD_COURSE
} from '../db/harvard';

@path: 'cambridge-service'
service CambridgeService {
    entity Courses         as projection on hv.Course;
    entity Subjects        as projection on hv.Subjects;
    entity Students        as projection on hv.Students;
    entity Grade_Subject   as projection on hv.Grade_Subject;

    @readonly
    entity HarvardStudents as projection on HARVARD_STUDENTS;

    @readonly
    entity HarvardSubjects as projection on HARVARD_SUBJECTS;

    @readonly
    entity HarvardCourses  as projection on HARVARD_COURSE;
}
