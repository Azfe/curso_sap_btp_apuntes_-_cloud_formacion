import cds from '@sap/cds'

export default class HarvardService extends cds.ApplicationService {
    async init() {

        const { Students, Courses } = this.entities;

        this.on('enroll', async (req) => {
            const { studentID, courseID } = req.data;

            // Verificar que existen
            const student = await SELECT.one.from(Students).where({ ID: studentID });
            const course = await SELECT.one.from(Courses).where({ ID: courseID });

            if (!student || !course) {
                return { success: false, message: 'Alumno o curso no encontrado' }
            }

            return { success: true, message: `${student.name} matriculado en ${course.name}` };
        })

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
        })

        await super.init();
    }
}
