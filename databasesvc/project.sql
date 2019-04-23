
DROP USER 'myuser';
CREATE USER 'myuser'@'%' IDENTIFIED WITH mysql_native_password BY 'mypassword';
GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'%';

FLUSH PRIVILEGES;

USE mydb;

CREATE TABLE contract (
  id int(11) NOT NULL AUTO_INCREMENT,
  contractnumber varchar(45) DEFAULT NULL,
  product varchar(45) DEFAULT NULL,
  amount decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY idcontract_UNIQUE (id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE products (
    product_code VARCHAR(10),
    product_description VARCHAR(256),
    PRIMARY KEY (product_code));

INSERT INTO mydb.products (product_code, product_description) VALUES ('MIN', 'Een minimalistisch product');
INSERT INTO mydb.products (product_code, product_description) VALUES ('TOP', 'Een TOP product');

COMMIT;
