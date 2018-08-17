<?php
/*
| For additional options see
| https://github.com/octobercms/october/blob/master/config/filesystems.php
*/

return [
    
    /*
    |--------------------------------------------------------------------------
    | Default Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default filesystem disk that should be used
    | by the framework. A "local" driver, as well as a variety of cloud
    | based drivers are available for your choosing. Just store away!
    |
    | Supported: "local", "s3", "rackspace"
    |
    */
    
    'default' => env('FS_DEFAULT', 'local'),
    
    /*
    |--------------------------------------------------------------------------
    | Default Cloud Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Many applications store files both locally and in the cloud. For this
    | reason, you may specify a default "cloud" driver here. This driver
    | will be bound as the Cloud disk implementation in the container.
    |
    */
    
    'cloud' => env('FS_CLOUD', 's3'),
    
    /*
    |--------------------------------------------------------------------------
    | Filesystem Disks
    |--------------------------------------------------------------------------
    |
    | Here you may configure as many filesystem "disks" as you wish, and you
    | may even configure multiple disks of the same driver. Defaults have
    | been setup for each driver as an example of the required options.
    |
    */
    
    'disks' => [

        'local' => [
            'driver' => 'local',
            'root'   => storage_path('app'),
        ],

        's3' => [
            'driver' => 's3',
            'key'    => env('FS_S3_KEY', 'your-key'),
            'secret' => env('FS_S3_SECRET', 'your-secret'),
            'region' => env('FS_S3_REGION', 'your-region'),
            'bucket' => env('FS_S3_BUCKET', 'your-bucket'),
        ],

        'rackspace' => [
            'driver'    => 'rackspace',
            'username'  => env('FS_RS_USERNAME', 'your-username'),
            'key'       => env('FS_RS_KEY', 'your-key'),
            'container' => env('FS_RS_CONTAINER', 'your-container'),
            'endpoint'  => env('FS_RS_ENDPOINT', 'https://identity.api.rackspacecloud.com/v2.0/'),
            'region'    => env('FS_RS_REGION', 'IAD'),
        ],

    ],
];
