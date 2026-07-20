Config = {}

-- Cambia estas coordenadas por la oficina de cada faccion o negocio.
Config.Computers = {
    {
        label = 'Terminal de gestión',
        coords = vec3(455.2048, -930.862732, 34.0772438),
        heading = 0.0,
        model = 'm25_1_prop_m51_laptop_02a',
        chair = {
            coords = vec3(455.0140, -931.9128, 33.88),
            heading = 140.0,
            model = 'vw_prop_vw_offchair_01'
        },
        zone = {
            name = 'PUNTO COMISARIA',
            points = {
                vec3(459.35000610352, -933.45001220703, 34.0),
                vec3(459.04998779297, -922.09997558594, 34.0),
                vec3(450.0, -922.0, 34.0),
                vec3(450.04998779297, -933.70001220703, 34.0),
            },
            thickness = 4.0,
        },
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
    }
}
