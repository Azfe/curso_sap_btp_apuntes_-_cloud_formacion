using { com.madrid.gestionconcursos as db } from '../db/schema';

service GestionConcursosService {
  entity Propiedades as projection on db.Propiedades;
  entity Empresas    as projection on db.Empresas;
  entity Concursos   as projection on db.Concursos;
}
