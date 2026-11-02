// 6.1.1 Definición de Servicios OData
// Tras crear el archivo harvard-service.cds, expon las entidades Students, Courses, Subjects como pyencciones OData.
// El servicio debe llamarse HarvardService

using uni.harvard as hv from '../db/schema';

// 6.1.4 Anotaciones de autorización
// Protege el servicio: los alumnos solo pueden leer sus propios datos, los profesores pueden editarlos, y solo los administradores pueden crear o eliminar registros.

// 💡 Los roles se definen xs.security.json(BTP app router) o en .cdsrc.json para pruebas locales con mock users. En local puedes somular con:
// cds.env.requires.auth = {kind : 'mocked', users: { Alice: { roles: ['Admin'] } }}

@requires: 'authenticated-user'
service HarvardService {
    @cds.redirection.target
    @restrict: [
        {grant: 'READ', to: 'Alumno', where: 'email = $user'},
        {grant: ['READ', 'UPDATE'], to: 'Profesor'},
        {grant: ['READ', 'CREATE', 'DELETE'], to: 'Admin'}
    ]
    // entity Students       as projection on hv.Students;
    entity Students       as projection on hv.Students {*, virtual estado : String};

    @restrict: [{grant: 'READ', to: 'authenticated-user'}, {grant: '*', to: 'Admin'}]
    entity Courses        as projection on hv.Courses excluding { students };

    @restrict: [{grant: 'READ', to: 'authenticated-user'}, {grant: '*', to: 'Admin'}]
    entity Subjects       as projection on hv.Subjects;

    @restrict: [{grant: 'READ', to: 'Profesor'}, {grant: '*', to: 'Admin'}]
    entity Enrollments    as projection on hv.Enrollments;
    @restrict: [{grant: ['READ', 'UPDATE'], to: 'Profesor'}, {grant: '*', to: 'Admin'}]
    entity Grades       as projection on hv.Grades;

    // 6.1.2 Proyecciones y restricciones
    // Crea una vista servicio PublicStudents que exponga solo nombre, apellido y edad (sin email ni finalGrade)
    // Márcala como solo de lectura
    @readonly
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

    // action con efectos (POST en OData)
    @requires: 'Admin'
    action   enroll(studentID: Students:ID, courseID: Courses:ID) returns {
        success : Boolean;
        message : String;
    };    

    // Función (sin efectos secundarios, GET)
    @requires: ['Profesor', 'Admin']
    function studentsHasPassed(courseID: Courses:ID)              returns array of Students;

    // 💡 La diferencia clave: action puede modificar datos (POST en OData), function es de solo lectura (GET). 
    // Las acciones bound se vinculan a una entidad específica: action Students: suspender (motivo: String)   

}

// 💡 CAP genera automáticamente enpoints OData v4 para cada entidad: GET /odata/v4/harvard/Students
// Esto da soporte a $filter, $expand, $select, etc. Solo con estas 3 líneas obtienes una API complemente funcional.
