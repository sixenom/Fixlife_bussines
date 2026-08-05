Config = {}

Config.Organizations = {
    police = {
        label = 'Terminal de gestion',
        job = 'police',
        features = {
            settings = true,
            members = true,
            vehicles = true,
            finance = true
        },
        zone = {
            name = 'PUNTO COMISARIA',
            points = {
                vec3(459.35000610352, -933.45001220703, 34.0),
                vec3(459.04998779297, -922.09997558594, 34.0),
                vec3(450.0, -922.0, 34.0),
                vec3(450.04998779297, -933.70001220703, 34.0)
            },
            thickness = 4.0
        },
        login = {
            logo = 'logos/lspd.webp',
            username = 'Administrador',
            password = '12345678'
        }
    },
    gymplaya = {
        label = 'Terminal de gestion',
        job = 'gym1',
        purchaseGymId = 'Gym_1',
        features = {
            settings = true,
            members = true,
            vehicles = true,
            finance = true,
            gymManagement = true
        },
        zone = {
            name = "GYMPLAYA",
            points = {
                vec3(-1196.0, -1587.0, 4.0), vec3(-1213.0, -1562.0, 4.0),
                vec3(-1211.0, -1556.0, 4.0), vec3(-1203.0, -1555.0, 4.0),
                vec3(-1185.0, -1580.0, 4.0)
            },
            thickness = 4.0
        },
        login = {
            logo = 'logos/lspd.webp',
            username = 'Administrador',
            password = '12345678'
        }
    },
    hospital9335 = {
        label = 'Terminal de gestion',
        job = 'ambulance',
        features = {
            settings = true,
            members = true,
            vehicles = true,
            finance = true,
        },
        zone = {
                name = "HOSPITAL",
                points = {
                    vec3(1117.1999511719, -1559.9000244141, 40.0),
                    vec3(1124.0999755859, -1559.9000244141, 40.0),
                    vec3(1124.0999755859, -1566.9499511719, 40.0),
                    vec3(1117.1999511719, -1567.0, 40.0),
                },
                thickness = 4.0,
        },
        login = {
            logo = 'logos/lspd.webp',
            username = 'Administrador',
            password = '12345678'
        }
    },

}

Config.ManagementTypes = {
    laptop = {
        model = 'm25_1_prop_m51_laptop_02a',
        chair = {model = 'vw_prop_vw_offchair_01'},
        entry = {
            dict = 'anim@scripted@player@fix_agy_ig6_office_chair_entry@male@',
            pedClip = 'enter',
            chairClip = 'enter_chair',
            exitClip = 'exit',
            exitChairClip = 'exit_chair',
            computerIdleClip = 'computer_idle',
            computerIdleChairClip = 'computer_idle_chair',
            computerExitClip = 'computer_exit',
            computerExitChairClip = 'computer_exit_chair'
        }
    },
    tablet = {model = 'm25_2_prop_m52_aitablet_03a'}
}
