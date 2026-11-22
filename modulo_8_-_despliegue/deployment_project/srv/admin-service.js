import cds from '@sap/cds'

export class AdminService extends cds.ApplicationService { init() {

  const { Books } = this.entities
  const url = process.env.url;
  const url2 = process.env.url2;

  /**
   * Generate IDs for new Books drafts
   */
  this.before ('NEW', Books.drafts, async (req) => {
    if (req.data.ID) return
    const { ID:id1 } = await SELECT.one.from(Books).columns('max(ID) as ID')
    const { ID:id2 } = await SELECT.one.from(Books.drafts).columns('max(ID) as ID')
    req.data.ID = Math.max(id1||0, id2||0) + 1
  })

  this.on("getUrl", async(req) => {
    if(req.data.book === "El valle de los lobos"){
      return url;
    } else {
      return url2
    }
  })

  return super.init()
}}
