namespace uni.cambridge;

using {
    cuid,
    managed
} from '@sap/cds/common';

type Email : String(100);

entity Course : cuid {
    name       : String(50);
    start_date : Date;
    signatures : Association to Subjects;
    students   : Association to Students;
}

entity Subjects : cuid, managed {
    title  : String(50);
    course : Association to Course;
}

entity Grade_Subject : cuid, managed {
    grade     : Integer; // una nota por asignatura
    signature : Association to one Subjects;
    student   : Association to one Students;
}

entity Students : cuid {
    name       : String(50);
    surname    : String(50);
    age        : Integer;
    email      : Email;
    grades     : Composition of many Grade_Subject
                     on grades.student = $self;
    finalGrade : Integer @readonly; // calculado, no introducido a mano
}
