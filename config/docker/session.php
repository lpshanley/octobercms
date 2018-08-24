<?php
/*
| For additional options see
| https://github.com/octobercms/october/blob/master/config/session.php
*/

return [
    'driver' => env('SESSION_DRIVER','file'), // file, redis, etc
    'cookie' => env('SESSION_COOKIE_NAME', 'october_session'),
    'path' => env('SESSION_COOKIE_PATH', '/'),
    'domain' => env('SESSION_COOKIE_DOMAIN', null),
    'secure' => env('SESSION_COOKIE_SECURE', false)
];
