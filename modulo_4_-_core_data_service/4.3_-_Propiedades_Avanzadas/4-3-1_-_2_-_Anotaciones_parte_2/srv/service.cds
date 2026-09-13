using com.anotaciones as an from '../db/schema';

service CatalogService @(path:'/catalog') {    
    entity Orders as projection on an.Orders;
    entity Settings as projection on an.Settings;
}