# Control de transacciones

Proyecto SFDX para registrar depósitos y retiros inmutables sobre `Cuenta_Bancaria__c`.

## Contenido

- `Cuenta_Bancaria__c`: autonumérica, saldo monetario requerido (valor inicial `0`) y estado `Activa` o `Bloqueada`.
- `Transaccion__c`: autonumérica, relación maestro-detalle a la cuenta, tipo `Deposito` o `Retiro` y monto requerido.
- La validation rule `Monto_Mayor_Que_Cero` rechaza montos menores o iguales a cero sin Apex.
- `TransaccionTrigger` delega toda su lógica a `TransaccionTriggerHandler`.
- `CuentaSelector` concentra las consultas de cuentas; durante la validación usa `FOR UPDATE` para serializar retiros concurrentes.
- `TransaccionService` valida, proyecta el saldo dentro de un lote, actualiza cuentas y bloquea cambios o eliminaciones.

## Decisiones de diseño

La validación ocurre en `before insert` y la actualización del saldo en `after insert`: así una transacción que no se guarda nunca altera una cuenta. El mapa `saldoProyectado` impide sobregiros acumulados en el mismo lote, y se emite un único `update` de cuentas por lote. No hay SOQL ni DML dentro de loops.

Los mensajes de Apex están en Custom Labels y los valores de dominio viven en `TransaccionConstants`. La única excepción es el texto de la validation rule: Salesforce almacena el atributo `errorMessage` de esa metadata como texto estático y no resuelve Custom Labels en él; se mantiene sincronizado con `Monto_Debe_Ser_Mayor_A_Cero` y se verifica mediante la prueba correspondiente.

No se usan fflib, interfaces, inyección de dependencias, Custom Metadata para interruptores de reglas, Queueable ni Batch. Para un único objeto transaccional y tres reglas, esas abstracciones añadirían complejidad sin aportar valor.

## Pruebas

`TransaccionServiceTest` verifica depósitos, retiros válidos e inválidos, cuenta bloqueada, proyección de dos retiros en el mismo lote, 200 depósitos, inmutabilidad y la validation rule. Las pruebas evalúan resultados y saldos persistidos, no solo cobertura.

## Despliegue

Requiere Salesforce CLI (`sf`) y una org de destino.

```powershell
sf org login web --alias mi-org
sf project deploy start --source-dir force-app --target-org mi-org
sf apex run test --target-org mi-org --test-level RunLocalTests --result-format human --wait 20
```

## GitHub

Inicializa el repositorio y publícalo en una cuenta con GitHub CLI autenticado:

```powershell
git init
git add .
git commit -m "feat: control de transacciones Apex"
gh repo create control-de-transacciones --private --source . --remote origin --push
```
