#Práctica MBaaS - Scoops

Se ha montado en Azure un **Mobile App** con una tabla *scoops* en la que se almacenan los scoops que escriben los usuarios autenticador por **Facebook** a través del cliente móvil.

La tabla **scoops** consta de los siguientes campos:

- id
- title
- scooptext
- author
- authorID
- status
- latitude
- longitude
- personsScoring
- averageScore
- imageURL
- __createdAt
- __updatedAt
- __version
- __deleted

## APIs de Azure

Del lado del servidor de Azure que se han implementado algunas APIs:

- getURLForBlobInContainer - Devuelve el sas url para subir la foto al contenedor de la app
- getFacebookInfo - Devuelve los datos del usuario autentificado por Facebook

El repositorio del Back End esta en:

[https://github.com/chmoncada/scoopsBackend](https://github.com/chmoncada/scoopsBackend)

## Webjob

Se ha implementado un *webjob* para modificar los status de los scoops a publicar, el cual corre cada hora:

~~~js
var sql = require('mssql');

sql.connect("mssql://{miusername}:{mipassword}@{misqlserver}.database.windows.net:1433/{miDB}?encrypt=true")
    .then(function() {
    
        new sql.Request().query("UPDATE scoops SET status = 'published' WHERE status = 'pending'")
            .then(function(recordset) {
                console.log("All pending scoops published");
            }).catch(function(err) {
                console.error(err);
            });

    }).catch(function(err) {
        console.error(err);
    });
~~~

