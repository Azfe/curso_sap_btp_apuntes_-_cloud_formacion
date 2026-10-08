using uni.harvard as hv from '../db/schema';

@path: 'harvard-service'
service HarvardService {
    @cds.redirection.target
    entity Courses              as projection on hv.Course;

    entity Subjects             as projection on hv.Subjects;

    @cds.redirection.target
    entity Students             as projection on hv.Students;

    @cds.redirection.target
    entity Grade_Subject        as projection on hv.Grade_Subject;

    entity CourseStudent        as projection on hv.CourseStudent;

    @readonly
    entity ResumeStudentsCourse as projection on hv.ResumeStudentCourse;

    entity FullStudent          as projection on hv.FullStudent;
    entity StudentState         as projection on hv.StudentState;

    entity SubjectStadistic     as projection on hv.SubjectStadistic;
    entity DistributionAge      as projection on hv.DistributionAge;
    entity GradeReport          as projection on hv.GradeReport;
    entity StudentWithoutGrade  as projection on hv.StudentWithoutGrade;
    entity OrderedSubjects      as projection on hv.OrderedSubjects;
}
