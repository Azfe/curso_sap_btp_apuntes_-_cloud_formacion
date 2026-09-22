using { com.empresa.gestionedificios as db } from '../db/schema';

service GestionEdificiosService {
  entity Clientes    as projection on db.Clientes;
  entity Propiedades as projection on db.Propiedades;
  entity Contratos   as projection on db.Contratos;
}
