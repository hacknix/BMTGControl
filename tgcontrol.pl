#!/usr/bin/perl

use strict;

use Data::Dumper;

BEGIN { push(@INC,'../BrandMeister-API/lib/');}


use BrandMeister::API;


sub main {
    my($bmobj) = BrandMeister::API->new({
        BM_APIKEY  =>   'oIp8qzFiT.vIrJ63.agTf.yPILicyCUWih2IRH$HGtn49u88Eo.UmxG1fZeOy6IQnKwbotT1Xe64IecjDbbZIR.YOcJjio7G6DSu4Iw@XC3CRgWrr4o7Wm2HzM.S85ve',
        DMRID       => '235135',
    });
    my($res,$code,$message);
    $bmobj->dropdynamic(2);
    $res = $bmobj->json_response;
    print("$$res{code} $$res{message}\n");
    print('Jsonres: '.$bmobj->json_response."\n");
    $bmobj->add_static_tg(1,2351);
    print('Res: '.$bmobj->result."\n");
    print('Jsonres: '.Data::Dumper->Dump([$bmobj->json_response])."\n");
    $bmobj->del_static_tg(1,2351);
    print('Res: '.$bmobj->result."\n");
    print('Jsonres: '.Data::Dumper->Dump([$bmobj->json_response])."\n");
    
};

&main;
