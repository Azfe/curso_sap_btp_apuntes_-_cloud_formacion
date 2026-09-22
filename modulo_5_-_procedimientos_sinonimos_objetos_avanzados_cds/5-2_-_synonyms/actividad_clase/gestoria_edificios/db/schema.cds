namespace com.empresa.gestionedificios;

using { cuid, managed } from '@sap/cds/common';

entity Clientes : cuid, managed {
  nombre     : String(100)  @mandatory;
  apellidos  : String(100);
  nif        : String(20);
  email      : String(150);
  telefono   : String(20);
  direccion  : String(200);
    
}

entity Propiedades : cuid, managed {
  referenciaCatastral : String(30);
  direccion           : String(200) @mandatory;
  ciudad              : String(100);
  codigoPostal        : String(10);
  tipoInmueble        : String(30) enum { Piso; Local; Oficina; Nave; Edificio };
  superficieM2        : Decimal(10,2);
  disponible          : Boolean default true;
  contratos           : Association to many Contratos on contratos.propiedad = $self;
}

entity Contratos : cuid, managed {
  tipoOperacion : String(10) enum { Alquiler; Venta } default 'Alquiler';
  cliente       : Association to Clientes @mandatory;
  propiedad     : Association to Propiedades @mandatory;
  fechaInicio   : Date;
  fechaFin      : Date; 
  importe       : Decimal(12,2); // importe de alquiler o venta
  estado        : String(15) enum { Activo; Finalizado; Cancelado } default 'Activo';
}
