namespace uni.harvard;

using {
    cuid,
    managed
} from '@sap/cds/common';

type Email : String(100);

entity Course : cuid {
    name       : String(50);
    start_date : Date;
    subjects   : Association to Subjects;
    students   : Association to many CourseStudent
                     on students.course = $self;
}

entity CourseStudent {
    key course  : Association to one Course;
    key student : Association to one Students;
}

entity Subjects : cuid, managed {
    title  : String(50);
    course : Association to Course;
}

entity Grade_Subject : cuid, managed {
    grade   : Integer; // una nota por asignatura
    subject : Association to one Subjects;
    student : Association to one Students;
}

entity Students : cuid {
    name       : String(50);
    surname    : String(50);
    age        : Integer;
    email      : Email;
    grades     : Composition of many Grade_Subject
                     on grades.student = $self;
    finalGrade : Integer @readonly; // calculado, no introducido a mano
    courses    : Association to many CourseStudent
                     on courses.student = $self;
}

/*************** VISTAS CDS ***************/
// 1. Crea una vista CDS que muestre, para cada curso, el título y cuántos alumnos están matriculados. Navega la alumnos desde curso.
// Utilizando asociaciones y group by

// Vista: resumen de alumnos por curso
define view ResumeStudentCourse as
    select from Course as c {
        key c.ID,
            c.name                       as NameCourse,
            // Qué campo calculado añades contar almunos?
            count(c.students.student.ID) as NumberStudents : Integer
    // Qué necesitas en group by?
    }
    group by
        c.ID,
        c.name;

// La notación c.students.student.ID navega a la asociación directamente en la query, CAP la traduce al JOIN correspondiente a HANA

// Define una vista sobre Grade_Subject que muestre el título de cada asignatura, la nota media y el número total de alumnos examinados.
// Utilizando avg - group by - asociaciones anidadas

define view AverageGradesBySubject as
    select from Grade_Subject {
        subject.title as Subject,
        AVG(grade)    as AverageGrade   : Decimal,
        COUNT( * )    as NumberStudents : Integer
    }
    group by
        subject.ID,
        subject.title;
// Cuando se usa AVG() u otras funciones de agregación, todos los campos no-agregados deben aparecer en el group by. Para navegar a la asociación del group by
// se puede usar tanto subject.ID como el campo directo.

// 3. Define una vista que liste únicamente los alumnos con final_grade >= 5, mostrando su nombre, apellidos y nota. Ordena por nota por orden descendente.
// Utilizando WHERE - filtrado en vistas CDS - ORDER BY
define view StudentsHavePassed as
    select from Students as s {
        key s.ID,
            s.name,
            s.surname,
            s.finalGrade as FinalGrade
    }
    where
        finalGrade >= 5
    order by
        s.finalGrade desc;
// 💡 El WHERE en una vista CDS se aplica permanentemente: Cualquier OData query sobre esta vista heredará ese filtro. Es difrente a aplicar $filter
// desde el cliente.

/*************** CAMPOS CALCULADOS ***************/
// 4. Define un campo calculado NombreCompleto que una nombre y apellidos con espacio. Incluye también el email y la nota final.
// Campo calculado: Nombre completo
// Concatenación con ||

define view FullStudent as
    select from Students {
        ID,
        name || ' ' || surname as FullName : String,
        email,
        finalGrade
    }

// 💡 El operador de concatenación en CDS/CQL es '||'. Siempre anota el tipo (: String) en campos calculados para que CAP pueda inferir el tipo de
// OData correcto (Edm.String)

// 5. Añade un campo calculado Estado que devuelve 'Aprobado' si la nota final es >= 5 y 'Suspenso' es caso contrario. Combínalo con el nombre completo del
// ejercicio anterior.
// Utilizando case when - then - else - end

define view StudentState as
    select from Students {
        name || ' ' || surname as FullName : String,
        finalGrade             as FinalGrade,
        case
            when finalGrade >= 5
                 then 'Aprobado'
            else 'Suspenso'
        end                    as Estado   : String
    }
// El case when en CDS se traduce directamente a SQL CASE en Hana. Puedes añadir múltiples 'when' para rangos de notas: Sobresaliente, Notable,
// Aprobado, Suspenso...

/*************** AGREGACIONES Y AGRUPACIÓN ***************/
// 6. Define una vista que muestre para cada asignatura: nota mínima, máxima, media y número de alumnos.
// Usa having para mostrar solo las asignaturas con más de 2 alumnos o igual.
// Utilizando min - max - avg - count - having

// Estadísticas completas por asignaturas
define view SubjectStadistic as
    select from Grade_Subject {
        subject.title as Subject,
        min(grade)    as MinimumGrade  : Integer,
        max(grade)    as MaximumGrade  : Integer,
        avg(grade)    as MediaGrade    : Decimal,
        count(grade)  as TotalStudents : Integer
    }
    group by
        subject.ID,
        subject.title
    having
        count( * ) >= 2;

// 💡 'Where' filtra filas antes de agrupar. 'Having' filtra grupos después de agregar.
// Nunca usar where count(*) >= 2 es un error muy común

// 7. Agrupa los alumnos en tres tramos de edad: menores de 20 años, entre 20 y 25 inclusive, mayores de 25
// Muestra cuántos alumnos hay en cada tramo
// Utilizando case en group by - between

// Distribución de alumnos por tramo de edad
define view DistributionAge as
    select from Students {
        case
            when age < 20
                 then 'Menor de 20'
            when age between 20
                 and 25
                 then '20-25'
            else 'Mayor de 25'
        end        as AgeGroup      : String,
        count( * ) as StudentNumber : Integer
    }
    group by
        case
            when age < 20
                 then 'Menor de 20'
            when age between 20
                 and 25
                 then '20-25'
            else 'Mayor de 25'
        end;
// 💡 Cuando agrupemos por un campo calculado con case, hay que repetir la expresión completa en el group by.
// HANA no acepta el alias (AgeGroup) en el group by estándar de SQL.

/*************** JOINS Y UNIONES ***************/

// 8. Combina Student, Grade_Subject y Subject para obtener el nombre completo del alumno, el título de la asignatura y su nota.
// Ordenar por apellidos y asignatura.
// Utilizando JOIN múltiple - alias tabla

// Informe completo: alumno + asignatura + nota
define view GradeReport as
    select from Students as a
    join Grade_Subject as an
        on an.student.ID = a.ID
    join Subjects as s
        on an.subject.ID = s.ID
    {
        a.name || ' ' || a.surname as FullName : String,
        s.title                    as Subject,
        an.grade                   as Grade,
        a.finalGrade               as FinalGrade
    }
    order by
        a.surname,
        s.title;
// 💡 Los alias (as a, as an, as s) son esenciales con múltiples jonis, para evitar anbigüedades.
// Fíjate que en el on puedas navegar asociaciones con punto: an.student.ID

// 9. Define una lista de alumnos que todavía no tienen ningún registro en Grade_Subject.
// Muestra nombre, apellidos y email.
// Utilizando left join - IS NULL pattern

define view StudentWithoutGrade as
    select from Students as s
    left join Grade_Subject as sg
        on sg.student.ID = s.ID
    {
        s.name,
        s.surname,
        s.email
    }
    where
        sg.ID is null;
// 💡 El patrón LEFT JOIN ... WHERE lado_derecho IS NULL es la forma estándar de encontrar "registros huérfanos"
// o sin datos relacionados. Es más eficiente que usar NOT EXISTS en Hana.

// Crea una vista que muestre las asignaturas ordenadas de más difícil a más fácil (menor media primero), incluyendo la nota media y el porcentaje de
// alumnos suspensos (nota < 5).

define view OrderedSubjects as
    select from Subjects as s
    join Grade_Subject as gs
        on gs.subject.ID = s.ID
    {
        key s.ID,
            s.title                         as Subject,
            AVG(gs.grade)                   as AverageGrade  : Decimal(5, 2),
            sum(case
                    when gs.grade < 5
                         then 1
                    else 0
                end) * 100.0 / count(gs.ID) as FailedPercent : Decimal(5, 2)
    }
    group by
        s.ID,
        s.title
    order by
        AverageGrade asc;
