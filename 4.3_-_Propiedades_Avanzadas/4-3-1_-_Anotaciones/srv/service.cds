using com.bookshop_anotations as bka from '../db/schema';

service CatalogService {
    entity Book as projection on bka.Book;
    entity Libros as projection on bka.Libros;
    entity Product as projection on bka.Product;
    entity Books as projection on bka.Books;
    entity Authors as projection on bka.Authors;
}