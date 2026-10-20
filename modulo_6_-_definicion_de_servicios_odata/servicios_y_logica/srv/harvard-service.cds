// 6.1.1 Definición de Servicios OData
// Tras crear el archivo harvard-service.cds, expon las entidades Students, Courses, Subjects como pyencciones OData.
// El servicio debe llamarse HarvardService

using uni.harvard as hv from '../db/schema';

// @path: 'harvard-service'
service HarvardService {
    @cds.redirection.target
    entity Students       as projection on hv.Students;

    entity Courses        as projection on hv.Courses;
    entity Subjects       as projection on hv.Subjects;
    entity Enrollments    as projection on hv.Enrollments;

    // 6.1.2 Proyecciones y restricciones
    // Crea una vista servicio PublicStudents que exponga solo nombre, apellido y edad (sin email ni finalGrade)
    // Márcala como solo de lectura
    @Capabilities.DeleteRestrictions.Deletable
    entity PublicStudents as
        projection on hv.Students {
            ID,
            name,
            surname,
            age
        };
    // 💡 @readonly deshabilita automáticamente POST, UPDATE, PUT y DELETE en esa entidad del servicio.
    // También puede usar
    // @insertonly o @Capabilities.DeleteRestrictions.Deletable: false para un control más exhaustivo

    // 6.1.3 Acciones y Funciones
    // Define una acción "matricular" que recibe el ID alumno y el ID de un curso, y que devuelva un objeto con "éxito: Boolean" y "mensaje: String"
    action   enroll(studentID: Students:ID, courseID: Courses:ID) returns {
        success : Boolean;
        message : String;
    };

    // Función (sin efectos secundarios, GET)
    function studentsHasPassed(courseID: Courses:ID)              returns array of Students;


}

// 💡 CAP genera automáticamente enpoints OData v4 para cada entidad: GET /odata/v4/harvard/Students
// Esto da soporte a $filter, $expand, $select, etc. Solo con estas 3 líneas obtienes una API complemente funcional.
