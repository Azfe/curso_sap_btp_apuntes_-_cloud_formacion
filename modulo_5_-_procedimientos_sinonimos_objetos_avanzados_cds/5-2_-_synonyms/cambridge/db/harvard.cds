@cds.persistence.exists
entity HARVARD_STUDENTS {
    key ID         : UUID;
        name       : String(50);
        surname    : String(50);
        age        : Integer;
        email      : String(100);
        finalGrade : Integer;
}

@cds.persistence.exists
entity HARVARD_SUBJECTS {
    key ID         : UUID;
        createdAt  : Timestamp;
        createdBy  : String(255);
        modifiedAt : Timestamp;
        modifiedBy : String(255);
        title      : String(50);
        course_ID  : UUID;
}

@cds.persistence.exists
entity HARVARD_COURSE {
    key ID            : UUID;
        name          : String(50);
        start_date    : Date;
        signatures_ID : UUID;
        students_ID   : UUID;
}
