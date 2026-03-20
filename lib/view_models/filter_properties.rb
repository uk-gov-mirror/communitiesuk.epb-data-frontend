require "csv"
require "bytesize"

module ViewModels
  class FilterProperties
    def self.page_title(property_type)
      case property_type
      when "domestic"
        I18n.t("filter_properties.domestic_title")
      when "non-domestic"
        I18n.t("filter_properties.non-domestic_title")
      when "display"
        I18n.t("filter_properties.display_title")
      else
        ""
      end
    end

    def self.councils
      CSV.new(council_csv).each.to_a.flatten
    end

    def self.parliamentary_constituencies
      CSV.new(constituency_csv).each.to_a.flatten
    end

    def self.years
      (2012..Time.now.year).map(&:to_s)
    end

    def self.months
      I18n.t("date.months")
    end

    def self.start_year
      "2012"
    end

    def self.current_year
      Date.today.year.to_s
    end

    def self.previous_month
      (Date.today << 1).strftime("%B")
    end

    def self.start_date_from_inputs(year, month)
      raise Errors::InvalidDateArgument unless ViewModels::FilterProperties.months.include?(month)

      month_index = Date::MONTHNAMES.index(month)
      raise Errors::InvalidDateArgument if month_index.nil?

      Date.new(year.to_i, month_index)
    end

    def self.end_date_from_inputs(year, month)
      raise Errors::InvalidDateArgument unless ViewModels::FilterProperties.months.include?(month)

      month_index = Date::MONTHNAMES.index(month)
      raise Errors::InvalidDateArgument if month_index.nil?

      Date.new(year.to_i, month_index, -1)
    end

    def self.is_valid_date?(params)
      return true if params.empty?

      start_date = start_date_from_inputs(params["from-year"], params["from-month"])
      end_date = end_date_from_inputs(params["to-year"], params["to-month"])

      start_date < end_date
    end

    def self.council_csv
      <<~HEREDOC
        Aberafan Maesteg
        Adur
        Alyn and Deeside
        Amber Valley
        Arun
        Ashfield
        Ashford
        Babergh
        Bangor Aberconwy
        Barking and Dagenham
        Barnet
        Barnsley
        Basildon
        Basingstoke and Deane
        Bassetlaw
        Bath and North East Somerset
        Bedford
        Bexley
        Birmingham
        Blaby
        Blackburn with Darwen
        Blackpool
        Blaenau Gwent
        Blaenau Gwent and Rhymney
        Bolsover
        Bolton
        Boston
        "Bournemouth, Christchurch and Poole"
        Bracknell Forest
        Bradford
        Braintree
        Breckland
        "Brecon, Radnor and Cwm Tawe"
        Brent
        Brentwood
        Bridgend
        Brighton and Hove
        "Bristol, City of"
        Broadland
        Bromley
        Bromsgrove
        Broxbourne
        Broxtowe
        Buckinghamshire
        Burnley
        Bury
        Caerfyrddin
        Caerphilly
        Calderdale
        Cambridge
        Camden
        Cannock Chase
        Canterbury
        Cardiff
        Cardiff East
        Cardiff North
        Cardiff South and Penarth
        Cardiff West
        Carmarthenshire
        Castle Point
        Central Bedfordshire
        Ceredigion
        Ceredigion Preseli
        Charnwood
        Chelmsford
        Cheltenham
        Cherwell
        Cheshire East
        Cheshire West and Chester
        Chesterfield
        Chichester
        Chorley
        City of London
        Clwyd East
        Clwyd North
        Colchester
        Conwy
        Cornwall
        Cotswold
        County Durham
        Coventry
        Crawley
        Croydon
        Cumberland
        Dacorum
        Darlington
        Dartford
        Denbighshire
        Derby
        Derbyshire Dales
        Doncaster
        Dorset
        Dover
        Dudley
        Dwyfor Meirionnydd
        Ealing
        Eastbourne
        East Cambridgeshire
        East Devon
        East Hampshire
        East Hertfordshire
        Eastleigh
        East Lindsey
        East Riding of Yorkshire
        East Staffordshire
        East Suffolk
        Elmbridge
        Enfield
        Epping Forest
        Epsom and Ewell
        Erewash
        Exeter
        Fareham
        Fenland
        Flintshire
        Folkestone and Hythe
        Forest of Dean
        Fylde
        Gateshead
        Gedling
        Gloucester
        Gosport
        Gower
        Gravesham
        Great Yarmouth
        Greenwich
        Guildford
        Gwynedd
        Hackney
        Halton
        Hammersmith and Fulham
        Harborough
        Haringey
        Harlow
        Harrow
        Hart
        Hartlepool
        Hastings
        Havant
        Havering
        "Herefordshire, County of"
        Hertsmere
        High Peak
        Hillingdon
        Hinckley and Bosworth
        Horsham
        Hounslow
        Huntingdonshire
        Hyndburn
        Ipswich
        Isle of Anglesey
        Isle of Wight
        Isles of Scilly
        Islington
        Kensington and Chelsea
        King's Lynn and West Norfolk
        "Kingston upon Hull, City of"
        Kingston upon Thames
        Kirklees
        Knowsley
        Lambeth
        Lancaster
        Leeds
        Leicester
        Lewes
        Lewisham
        Lichfield
        Lincoln
        Liverpool
        Llanelli
        Luton
        Maidstone
        Maldon
        Malvern Hills
        Manchester
        Mansfield
        Medway
        Melton
        Merthyr Tydfil
        Merthyr Tydfil and Aberdare
        Merton
        Mid and South Pembrokeshire
        Mid Devon
        Middlesbrough
        Mid Suffolk
        Mid Sussex
        Milton Keynes
        Mole Valley
        Monmouthshire
        Montgomeryshire and Glyndwr
        Neath and Swansea East
        Neath Port Talbot
        Newark and Sherwood
        Newcastle-under-Lyme
        Newcastle upon Tyne
        New Forest
        Newham
        Newport
        Newport East
        Newport West and Islwyn
        North Devon
        North East Derbyshire
        North East Lincolnshire
        North Hertfordshire
        North Kesteven
        North Lincolnshire
        North Norfolk
        North Northamptonshire
        North Somerset
        North Tyneside
        Northumberland
        North Warwickshire
        North West Leicestershire
        North Yorkshire
        Norwich
        Nottingham
        Nuneaton and Bedworth
        Oadby and Wigston
        Oldham
        Oxford
        Pembrokeshire
        Pendle
        Peterborough
        Plymouth
        Pontypridd
        Portsmouth
        Powys
        Preston
        Reading
        Redbridge
        Redcar and Cleveland
        Redditch
        Reigate and Banstead
        Rhondda and Ogmore
        Rhondda Cynon Taf
        Ribble Valley
        Richmond upon Thames
        Rochdale
        Rochford
        Rossendale
        Rother
        Rotherham
        Rugby
        Runnymede
        Rushcliffe
        Rushmoor
        Rutland
        Salford
        Sandwell
        Sefton
        Sevenoaks
        Sheffield
        Shropshire
        Slough
        Solihull
        Somerset
        Southampton
        South Cambridgeshire
        South Derbyshire
        Southend-on-Sea
        South Gloucestershire
        South Hams
        South Holland
        South Kesteven
        South Norfolk
        South Oxfordshire
        South Ribble
        South Staffordshire
        South Tyneside
        Southwark
        Spelthorne
        Stafford
        Staffordshire Moorlands
        St Albans
        Stevenage
        St. Helens
        Stockport
        Stockton-on-Tees
        Stoke-on-Trent
        Stratford-on-Avon
        Stroud
        Sunderland
        Surrey Heath
        Sutton
        Swale
        Swansea
        Swansea West
        Swindon
        Tameside
        Tamworth
        Tandridge
        Teignbridge
        Telford and Wrekin
        Tendring
        Test Valley
        Tewkesbury
        Thanet
        Three Rivers
        Thurrock
        Tonbridge and Malling
        Torbay
        Torfaen
        Torridge
        Tower Hamlets
        Trafford
        Tunbridge Wells
        Uttlesford
        Vale of Glamorgan
        Vale of White Horse
        Wakefield
        Walsall
        Waltham Forest
        Wandsworth
        Warrington
        Warwick
        Watford
        Waverley
        Wealden
        Welwyn Hatfield
        West Berkshire
        West Devon
        West Lancashire
        West Lindsey
        Westminster
        Westmorland and Furness
        West Northamptonshire
        West Oxfordshire
        West Suffolk
        Wigan
        Wiltshire
        Winchester
        Windsor and Maidenhead
        Wirral
        Woking
        Wokingham
        Wolverhampton
        Worcester
        Worthing
        Wrexham
        Wychavon
        Wyre
        Wyre Forest
        Ynys Môn
        York
      HEREDOC
    end

    def self.constituency_csv
      <<~HEREDOC
        Aberafan Maesteg
        Aldershot
        Aldridge-Brownhills
        Altrincham and Sale West
        Alyn and Deeside
        Amber Valley
        Arundel and South Downs
        Ashfield
        Ashford
        Ashton-under-Lyne
        Aylesbury
        Banbury
        Bangor Aberconwy
        Barking
        Barnsley North
        Barnsley South
        Barrow and Furness
        Basildon and Billericay
        Basingstoke
        Bassetlaw
        Bath
        Battersea
        Beaconsfield
        Beckenham and Penge
        Bedford
        Bermondsey and Old Southwark
        Bethnal Green and Stepney
        Beverley and Holderness
        Bexhill and Battle
        Bexleyheath and Crayford
        Bicester and Woodstock
        Birkenhead
        Birmingham Edgbaston
        Birmingham Erdington
        Birmingham Hall Green and Moseley
        Birmingham Hodge Hill and Solihull North
        Birmingham Ladywood
        Birmingham Northfield
        Birmingham Perry Barr
        Birmingham Selly Oak
        Birmingham Yardley
        Bishop Auckland
        Blackburn
        Blackley and Middleton South
        Blackpool North and Fleetwood
        Blackpool South
        Blaenau Gwent
        Blaenau Gwent and Rhymney
        Blaydon and Consett
        Blyth and Ashington
        Bognor Regis and Littlehampton
        Bolsover
        Bolton North East
        Bolton South and Walkden
        Bolton West
        Bootle
        Boston and Skegness
        Bournemouth East
        Bournemouth West
        Bracknell
        Bradford East
        Bradford South
        Bradford West
        Braintree
        "Brecon, Radnor and Cwm Tawe"
        Brent East
        Brentford and Isleworth
        Brent West
        Brentwood and Ongar
        Bridgend
        Bridgwater
        Bridlington and The Wolds
        Brigg and Immingham
        Brighton Kemptown and Peacehaven
        Brighton Pavilion
        Bristol Central
        Bristol East
        Bristol North East
        Bristol North West
        Bristol South
        Broadland and Fakenham
        Bromley and Biggin Hill
        Bromsgrove
        Broxbourne
        Broxtowe
        Buckingham and Bletchley
        Burnley
        Burton and Uttoxeter
        Bury North
        Bury South
        Bury St Edmunds and Stowmarket
        Caerfyrddin
        Caerphilly
        Calder Valley
        Camborne and Redruth
        Cambridge
        Cannock Chase
        Canterbury
        Cardiff
        Cardiff East
        Cardiff North
        Cardiff South and Penarth
        Cardiff West
        Carlisle
        Carmarthenshire
        Carshalton and Wallington
        Castle Point
        Central Devon
        Central Suffolk and North Ipswich
        Ceredigion
        Ceredigion Preseli
        Chatham and Aylesford
        Cheadle
        Chelmsford
        Chelsea and Fulham
        Cheltenham
        Chesham and Amersham
        Chesterfield
        Chester North and Neston
        Chester South and Eddisbury
        Chichester
        Chingford and Woodford Green
        Chippenham
        Chipping Barnet
        Chorley
        Christchurch
        Cities of London and Westminster
        City of Durham
        Clacton
        Clapham and Brixton Hill
        Clwyd East
        Clwyd North
        Colchester
        Colne Valley
        Congleton
        Conwy
        Corby and East Northamptonshire
        Coventry East
        Coventry North West
        Coventry South
        Cramlington and Killingworth
        Crawley
        Crewe and Nantwich
        Croydon East
        Croydon South
        Croydon West
        Dagenham and Rainham
        Darlington
        Dartford
        Daventry
        Denbighshire
        Derby North
        Derbyshire Dales
        Derby South
        Dewsbury and Batley
        Didcot and Wantage
        Doncaster Central
        Doncaster East and the Isle of Axholme
        Doncaster North
        Dorking and Horley
        Dover and Deal
        Droitwich and Evesham
        Dudley
        Dulwich and West Norwood
        Dunstable and Leighton Buzzard
        Dwyfor Meirionnydd
        Ealing Central and Acton
        Ealing North
        Ealing Southall
        Earley and Woodley
        Easington
        Eastbourne
        East Grinstead and Uckfield
        East Ham
        East Hampshire
        Eastleigh
        East Surrey
        East Thanet
        East Wiltshire
        East Worthing and Shoreham
        Edmonton and Winchmore Hill
        Ellesmere Port and Bromborough
        Eltham and Chislehurst
        Ely and East Cambridgeshire
        Enfield North
        Epping Forest
        Epsom and Ewell
        Erewash
        Erith and Thamesmead
        Esher and Walton
        Exeter
        Exmouth and Exeter East
        Fareham and Waterlooville
        Farnham and Bordon
        Faversham and Mid Kent
        Feltham and Heston
        Filton and Bradley Stoke
        Finchley and Golders Green
        Flintshire
        Folkestone and Hythe
        Forest of Dean
        Frome and East Somerset
        Fylde
        Gainsborough
        Gateshead Central and Whickham
        Gedling
        Gillingham and Rainham
        Glastonbury and Somerton
        Gloucester
        Godalming and Ash
        Goole and Pocklington
        Gorton and Denton
        Gosport
        Gower
        Grantham and Bourne
        Gravesham
        Great Grimsby and Cleethorpes
        Great Yarmouth
        Greenwich and Woolwich
        Guildford
        Gwynedd
        Hackney North and Stoke Newington
        Hackney South and Shoreditch
        Halesowen
        Halifax
        Hamble Valley
        Hammersmith and Chiswick
        Hampstead and Highgate
        "Harborough, Oadby and Wigston"
        Harlow
        Harpenden and Berkhamsted
        Harrogate and Knaresborough
        Harrow East
        Harrow West
        Hartlepool
        Harwich and North Essex
        Hastings and Rye
        Havant
        Hayes and Harlington
        Hazel Grove
        Hemel Hempstead
        Hendon
        Henley and Thame
        Hereford and South Herefordshire
        Herne Bay and Sandwich
        Hertford and Stortford
        Hertsmere
        Hexham
        Heywood and Middleton North
        High Peak
        Hinckley and Bosworth
        Hitchin
        Holborn and St Pancras
        Honiton and Sidmouth
        Hornchurch and Upminster
        Hornsey and Friern Barnet
        Horsham
        Houghton and Sunderland South
        Hove and Portslade
        Huddersfield
        Huntingdon
        Hyndburn
        Ilford North
        Ilford South
        Ipswich
        Isle of Anglesey
        Isle of Wight East
        Isle of Wight West
        Islington North
        Islington South and Finsbury
        Jarrow and Gateshead East
        Keighley and Ilkley
        Kenilworth and Southam
        Kensington and Bayswater
        Kettering
        Kingston and Surbiton
        Kingston upon Hull East
        Kingston upon Hull North and Cottingham
        Kingston upon Hull West and Haltemprice
        Kingswinford and South Staffordshire
        Knowsley
        Lancaster and Wyre
        Leeds Central and Headingley
        Leeds East
        Leeds North East
        Leeds North West
        Leeds South
        Leeds South West and Morley
        Leeds West and Pudsey
        Leicester East
        Leicester South
        Leicester West
        Leigh and Atherton
        Lewes
        Lewisham East
        Lewisham North
        Lewisham West and East Dulwich
        Leyton and Wanstead
        Lichfield
        Lincoln
        Liverpool Garston
        Liverpool Riverside
        Liverpool Walton
        Liverpool Wavertree
        Liverpool West Derby
        Llanelli
        Loughborough
        Louth and Horncastle
        Lowestoft
        Luton North
        Luton South and South Bedfordshire
        Macclesfield
        Maidenhead
        Maidstone and Malling
        Makerfield
        Maldon
        Manchester Central
        Manchester Rusholme
        Manchester Withington
        Mansfield
        Melksham and Devizes
        Melton and Syston
        Meriden and Solihull East
        Merthyr Tydfil
        Merthyr Tydfil and Aberdare
        Mid and South Pembrokeshire
        Mid Bedfordshire
        Mid Buckinghamshire
        Mid Cheshire
        Mid Derbyshire
        Middlesbrough and Thornaby East
        Middlesbrough South and East Cleveland
        Mid Dorset and North Poole
        Mid Leicestershire
        Mid Norfolk
        Mid Sussex
        Milton Keynes Central
        Milton Keynes North
        Mitcham and Morden
        Monmouthshire
        Montgomeryshire and Glyndwr
        Morecambe and Lunesdale
        Neath and Swansea East
        Neath Port Talbot
        Newark
        Newbury
        Newcastle-under-Lyme
        Newcastle upon Tyne Central and West
        Newcastle upon Tyne East and Wallsend
        Newcastle upon Tyne North
        New Forest East
        New Forest West
        Newport
        Newport East
        Newport West and Islwyn
        Newton Abbot
        Newton Aycliffe and Spennymoor
        Normanton and Hemsworth
        Northampton North
        Northampton South
        North Bedfordshire
        North Cornwall
        North Cotswolds
        North Devon
        North Dorset
        North Durham
        North East Cambridgeshire
        North East Derbyshire
        North East Hampshire
        North East Hertfordshire
        North East Somerset and Hanham
        North Herefordshire
        North Norfolk
        North Northumberland
        North Shropshire
        North Somerset
        North Warwickshire and Bedworth
        North West Cambridgeshire
        North West Essex
        North West Hampshire
        North West Leicestershire
        North West Norfolk
        Norwich North
        Norwich South
        Nottingham East
        Nottingham North and Kimberley
        Nottingham South
        Nuneaton
        Old Bexley and Sidcup
        Oldham East and Saddleworth
        "Oldham West, Chadderton and Royton"
        Orpington
        Ossett and Denby Dale
        Oxford East
        Oxford West and Abingdon
        Peckham
        Pembrokeshire
        Pendle and Clitheroe
        Penistone and Stocksbridge
        Penrith and Solway
        Peterborough
        Plymouth Moor View
        Plymouth Sutton and Devonport
        "Pontefract, Castleford and Knottingley"
        Pontypridd
        Poole
        Poplar and Limehouse
        Portsmouth North
        Portsmouth South
        Powys
        Preston
        Putney
        Queen's Park and Maida Vale
        Rawmarsh and Conisbrough
        Rayleigh and Wickford
        Reading Central
        Reading West and Mid Berkshire
        Redcar
        Redditch
        Reigate
        Rhondda and Ogmore
        Rhondda Cynon Taf
        Ribble Valley
        Richmond and Northallerton
        Richmond Park
        Rochdale
        Rochester and Strood
        Romford
        Romsey and Southampton North
        Rossendale and Darwen
        Rotherham
        Rother Valley
        Rugby
        "Ruislip, Northwood and Pinner"
        Runcorn and Helsby
        Runnymede and Weybridge
        Rushcliffe
        Rutland and Stamford
        Salford
        Salisbury
        Scarborough and Whitby
        Scunthorpe
        Sefton Central
        Selby
        Sevenoaks
        Sheffield Brightside and Hillsborough
        Sheffield Central
        Sheffield Hallam
        Sheffield Heeley
        Sheffield South East
        Sherwood Forest
        Shipley
        Shrewsbury
        Sittingbourne and Sheppey
        Skipton and Ripon
        Sleaford and North Hykeham
        Slough
        Smethwick
        Solihull West and Shirley
        Southampton Itchen
        Southampton Test
        South Basildon and East Thurrock
        South Cambridgeshire
        South Cotswolds
        South Derbyshire
        South Devon
        South Dorset
        South East Cornwall
        Southend East and Rochford
        Southend West and Leigh
        Southgate and Wood Green
        South Holland and The Deepings
        South Leicestershire
        South Norfolk
        South Northamptonshire
        Southport
        South Ribble
        South Shields
        South Shropshire
        South Suffolk
        South West Devon
        South West Hertfordshire
        South West Norfolk
        South West Wiltshire
        Spelthorne
        Spen Valley
        Stafford
        Staffordshire Moorlands
        St Albans
        Stalybridge and Hyde
        St Austell and Newquay
        Stevenage
        St Helens North
        St Helens South and Whiston
        St Ives
        St Neots and Mid Cambridgeshire
        Stockport
        Stockton North
        Stockton West
        Stoke-on-Trent Central
        Stoke-on-Trent North
        Stoke-on-Trent South
        "Stone, Great Wyrley and Penkridge"
        Stourbridge
        Stratford and Bow
        Stratford-on-Avon
        Streatham and Croydon North
        Stretford and Urmston
        Stroud
        Suffolk Coastal
        Sunderland Central
        Surrey Heath
        Sussex Weald
        Sutton and Cheam
        Sutton Coldfield
        Swansea
        Swansea West
        Swindon North
        Swindon South
        Tamworth
        Tatton
        Taunton and Wellington
        Telford
        Tewkesbury
        The Wrekin
        Thirsk and Malton
        Thornbury and Yate
        Thurrock
        Tipton and Wednesbury
        Tiverton and Minehead
        Tonbridge
        Tooting
        Torbay
        Torfaen
        Torridge and Tavistock
        Tottenham
        Truro and Falmouth
        Tunbridge Wells
        Twickenham
        Tynemouth
        Uxbridge and South Ruislip
        Vale of Glamorgan
        Vauxhall and Camberwell Green
        Wakefield and Rothwell
        Wallasey
        Walsall and Bloxwich
        Walthamstow
        Warrington North
        Warrington South
        Warwick and Leamington
        Washington and Gateshead South
        Watford
        Waveney Valley
        Weald of Kent
        Wellingborough and Rushden
        Wells and Mendip Hills
        Welwyn Hatfield
        West Bromwich
        West Dorset
        West Ham and Beckton
        West Lancashire
        Westmorland and Lonsdale
        Weston-super-Mare
        West Suffolk
        West Worcestershire
        Wetherby and Easingwold
        Whitehaven and Workington
        Widnes and Halewood
        Wigan
        Wimbledon
        Winchester
        Windsor
        Wirral West
        Witham
        Witney
        Woking
        Wokingham
        Wolverhampton North East
        Wolverhampton South East
        Wolverhampton West
        Worcester
        Worsley and Eccles
        Worthing West
        Wrexham
        Wycombe
        Wyre Forest
        Wythenshawe and Sale East
        Yeovil
        Ynys Môn
        York Central
        York Outer
      HEREDOC
    end

    def self.get_full_load_file_size(property_type, use_case)
      file_name = "full-load/#{property_type}-csv.zip"
      total_bytes_estimate = use_case.execute(file_name: file_name)
      ByteSize.new(total_bytes_estimate.round).to_s
    end

    private_class_method :council_csv
    private_class_method :constituency_csv
  end
end
