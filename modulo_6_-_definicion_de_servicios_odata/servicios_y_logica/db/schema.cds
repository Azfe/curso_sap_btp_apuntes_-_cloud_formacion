namespace uni.harvard;

using {
    cuid,
    managed
} from '@sap/cds/common';

type Email : String(100);

entity Courses : cuid {
    name       : String(50);
    start_date : Date;
    subjects : Association to many Subjects on subjects.course = $self;
    students   : Association to many Enrollments
                     on students.course = $self;
}

entity Enrollments {
    key course  : Association to one Courses;
    key student : Association to one Students;
}

entity Subjects : cuid, managed {
    title  : String(50);
    course : Association to Courses;
}

entity Grades : cuid, managed {
    grade   : Integer; // una nota por asignatura
    subject : Association to one Subjects;
    student : Association to one Students;
}

entity Students : cuid {
    name       : String(50);
    surname    : String(50);
    age        : Integer;
    email      : Email;
    grades     : Composition of many Grades
                     on grades.student = $self;
    finalGrade : Integer @readonly; // calculado, no introducido a mano
    courses    : Association to many Enrollments
                     on courses.student = $self;
}