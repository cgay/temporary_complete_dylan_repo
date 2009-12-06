module: openssl-wrapper

define C-function SSL-library-init
  result success :: <C-int>;
  c-name: "SSL_library_init"
end;

define C-function SSL-load-error-strings
  result res :: <C-void*>;
  c-name: "SSL_load_error_strings"
end;

define C-function ERR-load-BIO-strings
  result res :: <C-void*>;
  c-name: "ERR_load_BIO_strings"
end;

define C-function RAND-load-file
  input parameter filename :: <C-string>;
  input parameter maximal-bytes :: <C-int>;
  result read-bytes :: <C-int>;
  c-name: "RAND_load_file"
end;

define C-function BIO-new-connect
  input parameter host-and-port :: <C-string>;
  result bio :: <basic-input-output*>;
  c-name: "BIO_new_connect"
end;

define C-struct <STACK>
  slot number :: <C-int>;
  slot data :: <C-string*>;
  slot sorted :: <C-int>;
  slot number-alloc :: <C-int>;
  slot whatever :: <C-int>;
  pointer-type-name: <STACK*>;
end;

define C-struct <crypto-ex-data>
  slot sk :: <STACK>;
  slot dummy :: <C-int>;
  pointer-type-name: <crypto-ex-data*>;
end;

define C-struct <basic-input-output>
  slot bio-method :: <C-void*>; //actually BIO_METHOD*
  slot callback :: <C-void*>; //bio_st*, int, const char*, int, long, long => long
  slot callback-argument :: <C-string>;
  slot init :: <C-int>;
  slot shutdown :: <C-int>;
  slot flags :: <C-int>;
  slot retry-reason :: <C-int>;
  slot num :: <C-int>;
  slot ptr :: <C-void*>;
  slot next-bio :: <basic-input-output*>;
  slot previous-bio :: <basic-input-output*>;
  slot references :: <C-int>;
  slot number-read :: <C-unsigned-long>;
  slot number-write :: <C-unsigned-long>;
  slot ex-data :: <crypto-ex-data>;
  pointer-type-name: <basic-input-output*>;
end;

define C-function BIO-read
  input parameter bio :: <basic-input-output*>;
  parameter data :: <C-void*>; //buffer-offset>;
  input parameter length :: <C-int>;
  result read-bytes :: <C-int>;
  c-name: "BIO_read"
end;

define C-function BIO-write
  input parameter bio :: <basic-input-output*>;
  input parameter data :: <C-void*>; //buffer-offset>;
  input parameter length :: <C-int>;
  result written-bytes :: <C-int>;
  c-name: "BIO_write"
end;

define C-function SSL-new
  input parameter context :: <SSL-CTX>;
  result ssl :: <ssl*>;
  c-name: "SSL_new"
end;

define C-function SSL-read
  input parameter ssl :: <ssl*>;
  parameter data :: <C-void*>;
  input parameter length :: <C-int>;
  result read-bytes :: <C-int>;
  c-name: "SSL_read"
end;

define C-function SSL-write
  input parameter ssl :: <ssl*>;
  input parameter data :: <C-void*>;
  input parameter length :: <C-int>;
  result written-bytes :: <C-int>;
  c-name: "SSL_write"
end;

define C-function SSL-set-fd
  input parameter ssl :: <ssl*>;
  input parameter socket :: <C-int>;
  result res :: <C-int>;
  c-name: "SSL_set_fd"
end;

define C-function SSL-connect
  input parameter ssl :: <ssl*>;
  result res :: <C-int>;
  c-name: "SSL_connect"
end;

define C-function SSL-accept
  input parameter ssl :: <ssl*>;
  result res :: <C-int>;
  c-name: "SSL_accept"
end;

//hope that I can treat this as opaque
define constant <SSL-METHOD> = <C-void*>;

define C-function SSLv2-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv2_method"
end;

define C-function SSLv2-server-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv2_server_method"
end;

define C-function SSLv2-client-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv2_client_method"
end;

define C-function SSLv3-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv3_method"
end;

define C-function SSLv3-server-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv3_server_method"
end;

define C-function SSLv3-client-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv3_client_method"
end;

define C-function SSLv23-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv23_method"
end;

define C-function SSLv23-server-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv23_server_method"
end;

define C-function SSLv23-client-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "SSLv23_client_method"
end;

define C-function TLSv1-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "TLSv1_method"
end;

define C-function TLSv1-server-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "TLSv1_server_method"
end;

define C-function TLSv1-client-method
  result ssl-method :: <SSL-METHOD>;
  c-name: "TLSv1_client_method"
end;

//opaque!?
define constant <SSL-CTX> = <C-void*>;

define C-function SSL-context-new
  input parameter ssl-method :: <SSL-METHOD>;
  result ssl-context :: <SSL-CTX>;
  c-name: "SSL_CTX_new"
end;

define C-function BIO-new-ssl-connect
  input parameter context :: <SSL-CTX>;
  result bio :: <basic-input-output*>;
  c-name: "BIO_new_ssl_connect"
end;

define constant <ssl*> = <C-void*>;

//define C-struct <ssl>
//
//  pointer-type-name: <ssl*>;
//end;

define C-function SSL-context-use-certificate-file
  input parameter context :: <SSL-CTX>;
  input parameter filename :: <C-string>;
  input parameter type :: <C-int>;
  result res :: <C-int>;
  c-name: "SSL_CTX_use_certificate_file"
end;

define C-function SSL-context-use-private-key-file
  input parameter context :: <SSL-CTX>;
  input parameter filename :: <C-string>;
  input parameter type :: <C-int>;
  result res :: <C-int>;
  c-name: "SSL_CTX_use_PrivateKey_file"
end;

define C-function BIO-new-ssl
  input parameter context :: <SSL-CTX>;
  input parameter client :: <C-int>;
  result bio :: <basic-input-output*>;
  c-name: "BIO_new_ssl"
end;

define C-function BIO-new-accept
  input parameter host-port :: <C-string>;
  result bio :: <basic-input-output*>;
  c-name: "BIO_new_accept"
end;

define C-function BIO-pop
  input parameter bio :: <basic-input-output*>;
  result bio :: <basic-input-output*>;
  c-name: "BIO_pop"
end;

define C-function X509-new
  result x509 :: <x509>;
  c-name: "X509_new"
end;

//some constants
define constant $SSL-MODE-AUTO-RETRY = 4;
define constant $SSL-FILETYPE-PEM = 1;

//these are macros or other stuff defined in support.c
define C-function BIO-do-connect
  input parameter bio :: <basic-input-output*>;
  result res :: <C-long>;
  c-name: "my_BIO_do_connect"
end;

define C-function BIO-set-connection-hostname
  input parameter bio :: <basic-input-output*>;
  input parameter name :: <C-string>;
  result res :: <C-long>;
  c-name: "my_BIO_set_conn_hostname"
end;

define C-function BIO-get-ssl
  input parameter bio :: <basic-input-output*>;
  parameter ssl :: <ssl*>;
  result res :: <C-long>;
  c-name: "my_BIO_get_ssl"
end;

define C-function SSL-set-mode
  input parameter ssl :: <ssl*>;
  input parameter operation :: <C-long>;
  result res :: <C-long>;
  c-name: "my_SSL_set_mode"
end;

define C-function BIO-set-accept-bios
  input parameter b :: <basic-input-output*>;
  input parameter bio :: <basic-input-output*>;
  result res :: <C-long>;
  c-name: "my_BIO_set_accept_bios"
end;

define C-function BIO-do-accept
  input parameter b :: <basic-input-output*>;
  result res :: <C-long>;
  c-name: "my_BIO_do_accept"
end;

//define constant BIO-do-handshake = BIO-do-accept;

define constant <x509> = <C-void*>;

define C-pointer-type <x509**> => <x509>;

define C-function PEM-read-X509
  input parameter file :: <C-string>;
  input parameter x :: <x509**>;
  input parameter password-callback :: <C-void*>; //actually pem_password_cb*
  input parameter u :: <C-void*>;
  result x509 :: <x509>;
  c-name: "my_PEM_read_X509"
end;

define C-function SSL-context-add-extra-chain-certificate
  input parameter context :: <SSL-CTX>;
  input parameter x509 :: <x509>;
  result res :: <C-long>;
  c-name: "my_SSL_CTX_add_extra_chain_cert"
end;