import cds from '@sap/cds'

export default class HarvardService extends cds.ApplicationService {
    async init(){
    await super.init() // Llamada a la implementación de la clase padre para inicializar el servicio con csv data

        // Helper para resolver mensajes i18n

        const _msg = (req, key, ...params) => {
            let locale = req.locale ?? 'es';
            let text = cds.i18n.labels.at(key, locale, params) ?? key; // fallback al key si no existe

            return text;
        }

        // Implementación action SyncCambridge
        // this.on('SyncCambridge', async (req) => {
        //     const { email } = req.data;
        //     const db = await cds.connect.to('db')
        //     try {
        //         const result = await db.run(
        //             `CALL "SyncStudentCambridge"(
        //                 IV_EMAIL => ?,
        //                 )`
        //         )
        //     }
        // })
    }        
}