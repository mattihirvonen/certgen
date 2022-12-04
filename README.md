# certgen
Self Signed Certificate Generator
---------------------------------

Usage:  certgen.sh  [--clean] | [--text certfile] | [rootCAname certName]

Where

***rootCAname***   Root CA certificate file base name without extension. If file
                   exist, then use existing file and do not generate new file.

***certName***     Self signed certificate file base name.
               Uses "rootCAname" to sign new certificate file.
               File get Common Name (CN) field value same as "certName".
               File get DNS field values "certName" and "*.certName".

***--text***       Print out X509 certificate. "certfile" is full X509
               certificate file name with extension.

***--clean***      Remove all existing certificate information files.

