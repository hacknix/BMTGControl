#!/usr/bin/perl

use strict;

BEGIN { push(@INC,'../BrandMeister-API/lib/');}


use BrandMeister::API;


sub main {
    my($bmobj) = BrandMeister::API->new({
        BM_APIKEY  =>   'oIp8qzFiT.vIrJ63.agTf.yPILicyCUWih2IRH$HGtn49u88Eo.UmxG1fZeOy6IQnKwbotT1Xe64IecjDbbZIR.YOcJjio7G6DSu4Iw@XC3CRgWrr4o7Wm2HzM.S85ve',
        DMRID       => '235135',
    });
    
    $bmobj->dropdynamic;
    print('Res: '.$bmobj->result."\n");
    print('Jsonres: '.${$bmobj->json_response}."\n");
};

&main;
