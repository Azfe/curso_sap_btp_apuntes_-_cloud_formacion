namespace uni.harvard;

using { cuid, managed } from '@sap/cds/common';

type Email : String(100);

entity Course {
    name: String(20);
    start_date: Date;
    signatures: Association to Signatures;
    students: Association to Students;
}

entity Signatures : cuid, managed {
    title: String(20);
    grade: Integer;
    students : Association to Students;
} 

entity Grade_Signature : cuid, managed {
    grade: Integer;
    signature : Association to one Signatures;
    student : Association to one Students;
}

entity Students: cuid {
    name: String(50);
    surname: String(50);
    age: Integer;
    email : Email;
    finalGrade: Integer;
    signatures : Composition of Grade_Signature;
}

