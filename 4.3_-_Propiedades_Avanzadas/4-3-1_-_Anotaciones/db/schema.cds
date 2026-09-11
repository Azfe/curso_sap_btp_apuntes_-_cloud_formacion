namespace com.bookshop_anotations;

// 1. Anotaciones de Documentación

@title: 'Libro'
@description: 'Entidad que representa un libro en el catálogo'
entity Book {
    @title: 'Identificador'
    @description: 'ID único del libro'
    key ID: UUID;

    @title: 'Título del libro'
    @description: 'Nombre completo del Libro'
    title: String(100);

    @price: 'PVP'
    @description: 'Precio de venta al público del libro (PVP)'
    price: Decimal(10,2);

}

// 2. Anotaciones de UI (Fiori Elements)

@UI.HeaderInfo: {
    TypeName: 'Libro',
    TypeNamePlural: 'Libros',
    Title: {Value: title}
}

entity Libros {
    key ID: UUID;

    @UI.Hidden
    InternalCode: String(20);

    @title : 'Título'
    title: String(100);

    @title : 'Título'
    @Measures.ISOCurrency : currency_code
    price : Decimal(10,2);

    @title : 'Moneda'
    @Common.Label : 'Código divisa'
    currency_code : String(3);
}

// 3. Anotaciones de validación

entity Product {
    key ID : UUID;

    @mandatory
    name : String(100);

    @assert.range : [0, 100]
    price : Decimal(10, 2);
    
    @assert.range : [0, 5]
    rating : Decimal(2, 1);

    @assert.format : '^[A-Z]{2}[0-9]{8}$'
    ref_code_number : String(10);

    @asssert.unique
    bar_code : String(13)
}

// 4. Anotaciones de búsqueda

@cds.autoexpose
@cds.search : { title, author.name, ISBN }
entity Books {
    key ID : UUID;

    author : Association to Authors;

    postalCode : String(5);

    // URL
    @assert.format: '^(https?|ftp)://[^\s/$.?#].[^\s]*$'
    url : String(200);
}

entity Authors {
    key ID : UUID;
    name : String(100);
    books : Association to many Books
            on books.author = $self;
}
