namespace com.madrid.gestionconcursos;

using { cuid, managed } from '@sap/cds/common';

/**
 * 2.1 Propiedades: patrimonio inmobiliario de la Comunidad de Madrid
 */
entity Propiedades : cuid, managed {
  referenciaCatastral : String(30);
  direccion           : String(200) @mandatory;
  municipio           : String(100);
  codigoPostal        : String(10);
  tipoInmueble        : String(30) enum { Piso; Local; Oficina; Nave; Edificio; Solar };
  superficieM2        : Decimal(10,2);
  valorCatastral      : Decimal(14,2);
  concursos           : Association to many Concursos on concursos.propiedad = $self;
}

/**
 * 2.3 Empresas: empresas que pueden presentarse/resultar adjudicatarias de un concurso
 */
entity Empresas : cuid, managed {
  razonSocial : String(150) @mandatory;
  cif         : String(20);
  email       : String(150);
  telefono    : String(20);
  direccion   : String(200);
  concursos   : Association to many Concursos on concursos.empresaAdjudicataria = $self;
}

/**
 * 2.2 Concursos: licitación de una propiedad de la CAM, resuelta a favor de una empresa
 */
entity Concursos : cuid, managed {
  titulo                  : String(150) @mandatory;
  descripcion             : String(1000);
  tipoConcurso            : String(15) enum { Alquiler; Venta; Concesion } default 'Alquiler';
  propiedad               : Association to Propiedades @mandatory;
  empresaAdjudicataria    : Association to Empresas; // se asigna al resolver el concurso
  fechaPublicacion        : Date;
  fechaLimitePresentacion : Date;
  presupuestoBase         : Decimal(14,2);
  estado                  : String(15) enum { Abierto; Cerrado; Adjudicado; Anulado } default 'Abierto';
}
