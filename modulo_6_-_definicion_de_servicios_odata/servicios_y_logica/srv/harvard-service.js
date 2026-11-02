import cds from '@sap/cds'

export default class HarvardService extends cds.ApplicationService {
    async init() {

        const { Students, Courses, Subjects } = this.entities;

        // 6.2.1 Implementa un manejador before 'CREATE' en Students que valide: el nombre no puede estar vacío, el email debe contener @
        // y la edad debe ser mayor de 16.

        // this.before('CREATE', 'Students', (req) => {
        //     const {name, email, age} = req.data;

        //     if(!name?.trim()) {
        //         req.error(400, 'El nombre del alumno es obligatorio', 'name');
        //     }
        //     if(!email?.includes('@')){
        //         req.error(400, 'Email no válido', 'email');
        //     }

        //     if(age != null && age <= 16) {
        //         req.error(400, 'El alumno debe ser mayor de 16', 'age');
        //     }
        //     // 💡 El tercer parámetro de "req.error()" es el nombre del campo afectado. 
        //     // - OData lo incluyes en la respuesta del error como target, permitiendo que el front (Fiori Elements) resalte el campo error en concreto con el error.
        // })

        // 6.2.1 After - Añade un manejador after READ que enriquezca cada alumno con un campo virtual estado (Aprobado/Suspenso/Pendiente). 
        // calculado a partir de la nota final (finalGrade).

        this.after('READ', 'Students', (students) => {
            const list = Array.isArray(students) ? students : [students];

            list.forEach(student => {
                if(student.finalGrade === null || student.finalGrade === undefined){
                    student.estado = 'Pendiente';
                } else if(student.finalGrade >= 5){
                    student.estado = 'Aprobado';
                } else {
                    student.estado = 'Suspenso'
                }
            })
            // 💡 Para que 'estado' aparezca en el modelo OData, declararlo como campo virtual en el servicio:
            // entity Student as projection on harvard.Student {*, virtual estado : String}. Los campos virtuales no persisten en base de datos.
        })

        // 6.2.2 Operación personalizada - Implementa una función 'studentsHasPassed' definida en el servicio : recibe ID de un curso y devuelve la lista de 
        // alumnos con finalGrade >= 5 matriculados en ese curso.
        this.on('studentsHasPassed', async (req) => {
            const { courseID } = req.data;
            const { Enrollments } = this.entities;

            const course = await SELECT.one.from(Courses).where({ ID: courseID });
                        
            if (!course) return req.error(404, 'Curso no encontrado');

            // Alumnos matriculados en el curso con nota final >= 5
            return SELECT.from(Students).where({
                ID: { in: SELECT('student_ID').from(Enrollments).where({ course_ID: courseID }) },
                finalGrade: { '>=': 5 }
            });
            // 💡 'srv.on()' reemplaza el comportamiento genérico de CAP para esa operación. A diferencia del before/after, cuando se usa on se es responsable de toda
            // la lógica. Para funciones simples que solo leen datos, es suficiente devolver el resultado directamente.
        })
        
        // 6.2.3-4 Manejo de errores y transacciones - Implementa una acción matricular con manejo de transaccional completo: si falla cualquier paso, deshaz
        // todos los cambios. Usa req.reject para errores de negocio.

        this.on('enroll', async (req) => {
            const { studentID, courseID } = req.data;
            const { Enrollments, Grades } = this.entities;

            // Verificar que existen
            const student = await SELECT.one.from(Students).where({ ID: studentID });
            if(!student) return req.reject(404, "Alumno no encontrado")

            const course = await SELECT.one.from(Courses).where({ ID: courseID });
            if(!course) return req.reject(404, "Curso no encontrado")
            
            const already = await SELECT.one.from(Enrollments).where({ student_ID: studentID, course_ID: courseID });
            if (already) return req.reject(409, 'El alumno ya está matriculado en este curso');   

            // 1. Matrícula
            await INSERT.into(Enrollments).entries({ student_ID: studentID, course_ID: courseID });

            // 2. Una nota vacía por cada asignatura del curso
            const subjects = await SELECT.from(Subjects).columns('ID').where({ course_ID: courseID });
            if (subjects.length) {
                try {
                    await INSERT.into(Grades).entries(
                        subjects.map(s => ({ subject_ID: s.ID, student_ID: studentID }))
                    );
                } catch (error) {
                    // Traducimos solo el error de UNIQUE (@assert.unique en Grades); el resto se relanza tal cual.
                    // SQLite: "UNIQUE constraint failed" / HANA: "unique constraint violated"
                    if (/unique constraint/i.test(error.message)) {
                        return req.reject(409, 'El alumno ya tiene nota en alguna asignatura de este curso');
                    }
                    throw error;
                }
                // 💡 El catch termina siempre en req.reject o throw: así CAP sigue haciendo rollback de la matrícula.
                // Un "return" normal en el catch haría COMMIT y dejaría al alumno matriculado sin notas.
            }

            // CAP gestiona la transacción automáticamente dentro de un handler.
            // Para operaciones complejas multi-paso, cds.tx();

            // const tx = cds.tx(req);

            // if (!student || !course) {
            //     return { success: false, message: 'Alumno o curso no encontrado' }
            // }

            return { success: true, message: `${student.name} matriculado en ${course.name}` };
        })

        // 6.3.1 Consumo de servicios OData externos - Define una relación con el servicio externo enlazando el alumno con el Cliente (Customers)

        this.after('READ', 'Students', async (students) => {
            const list = Array.isArray(students) ? students : [students];
            try {
                const Northwind = await cds.connect.to("Northwind");
                for (const a of list) {
                    if (a.customer_CustomerID) {
                        const data = await Northwind.run(SELECT.from("Customers").where({ CustomerID: a.customer_CustomerID }));
                        if (data) a.customer = data[0];
                    }
                }
            } catch (error) {
                // El dato del cliente es opcional: sin Northwind, los alumnos se devuelven igual
                console.error('Northwind:', error.message);
            }
            // 💡 CAP abstrae el protocolo: puedes usar la misma sintaxis CQL (SELECT.from(...)) para servicios locales y externos. 
            // CAP traduce automáticamente la query a OData $filter, $select, etc. al ejecutarla contra el servicio externo.
        })

        // 6.3.2 Integración de API REST 
        // Integra una API REST de terceros (p. eje. servicio de verificación de emails) que no es OData. Llamar este desde un handler
        // before CREATE en Students para validar el email.

        // this.before('CREATE', 'Students', async (req) => {
        //     const {email} = req.data;
        //     if (!email?.includes('@')) return req.reject(400, 'Email no válido', 'email');

        //     let result;
            
        //     try {
        //         const EmailVerifier = await cds.connect.to('EmailVerifier');
        //         // CAP maneja la autenticación y headers configurados                
        //         result = await EmailVerifier.post('/verify', { email });

        //     } catch (error) {
        //         console.error('EmailVerifier:', error.message);
        //         return req.reject(503, 'Servicio de verificación de email no operativo');
        //     }
        //     if (result?.status !== 'valid') {
        //        return req.reject(400, `Email ${email} no es válido o inexistente`, 'email');
        //     }
        // })

        // 💡 Para las API REST que se requiere autenticación OAuth(como las de S/4HANA), se configura el destination Serice de BTP: CAP leerá las
        // credenciales automáticamente si define -- "kind" : "odata", "credentials": {"destination": "S4HG_PROD"}

        // 6.3.3 
        // Extiende el proyecto para que al crear un alumno, consulte la API Business Partner(A2X) de S4/HANA para verificar si existe el 
        // email como Business Partner. Usa el patrón façade de CAP.

        const S4BP = await cds.connect.to('API_BUSINESS_PARTNER');

        

        await super.init();
    }
}
