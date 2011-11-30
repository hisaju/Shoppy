CREATE TABLE IF NOT EXISTS comments (
  id integer PRIMARY KEY AUTOINCREMENT,
  asin text not null,
  title varchar(128) not null,
  url text not null,
  price integer default null,
  image_url text default null,
  comment text default null,
  created_at datetime default CURRENT_TIMESTAMP
);
