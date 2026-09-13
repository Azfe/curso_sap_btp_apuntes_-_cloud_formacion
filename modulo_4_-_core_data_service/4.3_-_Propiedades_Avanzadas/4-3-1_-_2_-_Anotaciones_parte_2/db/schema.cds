namespace com.anotaciones;

// 5. Anotaciones de Autorización

@requires: 'authenticated-user'
entity Orders {
    key ID: UUID;
    @readonly
    order_number: String(20);
    @capabilities.Updatable: false

    totalAmount: Decimal(15, 2);
}

@requires: 'Admin'
entity Settings {
    key ID: UUID;

    config_key: String(50);
    config_value : String(100);
}