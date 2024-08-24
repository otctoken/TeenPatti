module suiwin::suiwin {
    use sui::event::emit;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    use sui::sui::SUI;
    use sui::bls12381::bls12381_min_pk_verify;
    use sui::dynamic_object_field as dof;
    
    const EChangek: u64 = 0;
    const EChangekVol:u64 = 1;
    const EBetVol: u64 = 2;
    const EBetVolBig: u64 = 3;
    const EIngame : u64 = 4;
    const EAction: u64 = 5;
    const ERevealcards: u64 = 6;
    const EStage: u64 = 7;
    const EInvalidBlsSig: u64 = 8;
    const ECardThree: u64 = 9;
    const ECard: u64 = 10;
    const EOpencards: u64 = 11;
    const ETime: u64 = 12;
    const EPlayer: u64 = 13;
    const EOpencardsThree: u64 = 14;
    const ENotP: u64 = 15;

    const Adminadd: address = @0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44;

    public struct GameData has key {
        id: UID,
        balance: Balance<SUI>,
        fee:u8,
        countdown:u64,
        min:u64,
        max:u64,
        gamenumber:u64,

    }
    
    public struct WLock has key{
        id: UID,
        data: u64,

    }
    public struct AdminCap has key ,store{ id: UID }

    public struct PokerData has key,store {
        id: UID,
        balance: Balance<SUI>,
        player1:address,
        player2:address,
        sigcards1: vector<u8>,
        sigcards2: vector<u8>,
        revealcards1:vector<u8>,
        revealcards2:vector<u8>,
        stage:u8,
        bet:u64,
        time:u64,
        action: bool,
    }

    public struct GnumberOpen has copy,drop {
        result:u64,
        vol:u64,
    }
    public struct GnumberCont has copy,drop {
        result:u64,
        vol:u64,
    }
    public struct GnumberClose has copy,drop {
        result:u64,
    }

    public struct Gvol has copy,drop {
        vol:u64,
        player:address,
        expendORincome:bool,
    }

    public struct Testout has copy,drop {
        result:u8,
    }

    public entry fun change_WL(_: &AdminCap,wl:&mut WLock,ctx: &mut TxContext){
        wl.data = tx_context::epoch(ctx);

    }

    public entry fun change_data_fee(_: &AdminCap,fee:u8,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        assert!(fee < 51,EChangekVol);
        gamedata.fee=fee;
        wl.data = 9999999;
    }
    public entry fun change_data_countdown_down(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        gamedata.countdown = gamedata.countdown - 10000;
        assert!(gamedata.countdown > 20_000,EChangekVol);
        wl.data = 9999999;
    }
    public entry fun change_data_countdown_up(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        gamedata.countdown = gamedata.countdown + 10000;
        assert!(gamedata.countdown < 120_000,EChangekVol);
        wl.data = 9999999;
    }

    public entry fun change_data_min_down(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        gamedata.min = gamedata.min/2;
        assert!(gamedata.min > 100_000_000,EChangekVol);
        wl.data = 9999999;
    }
    public entry fun change_data_min_up(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        gamedata.min = gamedata.min * 2;
        assert!(gamedata.min < 55_000_000_000,EChangekVol);
        wl.data = 9999999;
    }


    public entry fun change_data_max_down(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        gamedata.max = gamedata.max/2;
        assert!(gamedata.max > 100_000_000_000,EChangekVol);
        wl.data = 9999999;
    }
    public entry fun change_data_max_up(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EChangek);
        gamedata.max = gamedata.max*2;
        assert!(gamedata.max < 1_000_000_000_000_000,EChangekVol);
        wl.data = 9999999;
    }

    public entry fun get_fee(vol:u64,gamedata:&mut GameData,ctx:&mut TxContext){
        let coina = coin::take(&mut gamedata.balance,vol,ctx);
        transfer::public_transfer(coina,Adminadd);
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, ctx.sender());
        transfer::share_object(GameData {
            id: object::new(ctx),
            balance:balance::zero(),
            countdown:60_000,
            fee:10,
            min:1_000_000_000,
            max:100_000_000_000,
            gamenumber:0,
        });
        transfer::share_object(WLock {
            id: object::new(ctx),
            data:9999999,
        });
    }


    fun verification_cards52(list: &vector<u8>): bool {
        let mut j: u8 = 1;
        while (j < 53) {
            let ver = vector::contains(list, &j);
            if (!ver) {
                return false
            };
            j = j + 1;
        };
        return true
    }

    fun verification_cards3(list: &vector<u8>): bool {
        let num1 = list[0];
        let num2 = list[1];
        let num3 = list[2];
        if (num1 == num2 || num1 == num3 || num2 == num3) {
            return false
        };
        if (num1 > 51 ||num2 > 51 ||  num3 > 51) {
            return false
        };
        return true
    }

    fun verification_reveal(a: &vector<u8>, b: &vector<u8>): bool {

        let mut i = 0;
        while (i < 3) {
            if (a[i] != b[i]) {
                return false
            };
            i = i + 1;
        };

        return true
    }


    fun get_high_cards(hand1: vector<u8>, hand2: vector<u8>): u8 {

        let value1 = get_values(hand1);
        let value2 = get_values(hand2);
        let mut values1 = handle_special_case(value1);
        let mut values2 = handle_special_case(value2);
    
        sort3(&mut values1);
        sort3(&mut values2);

        let mut i = 2;
        while (i >= 0) {
            if (values1[i] > values2[i]) {
                return 1 
            } else if (values1[i] < values2[i]) {
                return 2 
            };
            if (i == 0) {
                break
            };
            i = i - 1;
        };

        return 0
    }

    fun handle_special_case(hand: vector<u8>): vector<u8> {
        let mut result = vector::empty<u8>();
        let mut i = 0;
        while (i < vector::length(&hand)) {
            let value = hand[i];
            if (value == 1) {
                vector::push_back(&mut result, 14);
            } else {
                vector::push_back(&mut result, value);
            };
            i = i + 1;
        };
        result  // No need to use `return` keyword here; just return the result directly
    }

    fun get_cards_type(cards: vector<u8>):u8{
        let suits = get_suits(cards);
        let mut values = get_values(cards);
        if (values[0] == values[1] && values[1] == values[2]) {
            6
        }else{
            sort3(&mut values);
            let is_flush = suits[0] == suits[1] && suits[1] == suits[2];
            let is_straight = (values[2] - values[0] == 2 && values[2] - values[1] == 1) || 
                            (values[0] == 1 && values[1] == 12 && values[2] == 13); // A, Q, K
          
            if (is_flush && is_straight) {
            5
            } else if (is_straight) { 
            4
            }else if (is_flush) {  
            3
            }else if (values[0] == values[1] || values[1] == values[2] || values[0] == values[2]) { 
            2
            }else{
            1 
            }
        }
        
    }
    
    fun get_suits(cards: vector<u8>):vector<u8>{
        let mut result = vector::empty<u8>();
        let mut i = 0;
        while (i < 3) {
            let value = cards[i];
            let newcard = (value - 1) % 4;
            vector::push_back(&mut result, newcard);
            i = i + 1;
        };
        result
    }


    fun get_values(cards: vector<u8>):vector<u8>{
        let mut result = vector::empty<u8>();
        let mut i = 0;
        while (i < 3) {
            let value = cards[i];
            let newcard = (value - 1)/4 + 1;
            vector::push_back(&mut result, newcard);
            i = i + 1;
        };
        result
    }



    fun sort3(v: &mut vector<u8>) {
    
        if (v[0] > v[1]) {
            vector::swap(v, 0, 1);
        };

       
        if (v[1] > v[2]) {
            vector::swap(v, 1, 2);
        };

      
        if (v[0] > v[1]) {
            vector::swap(v, 0, 1);
        };
    }

    fun get_pair_value(cards:vector<u8>): u8 {
        let values1 = get_values(cards);
        let values = handle_special_case(values1);
        if(values[0]==values[1] || values[0]==values[2]){
            values[0]
        }else{
            values[1]
        }
    }

    fun compare_cards(hand1: vector<u8>, hand2: vector<u8>): u8 {
        let type1 = get_cards_type(hand1);
        let type2 = get_cards_type(hand2);
        if (type1 > type2) {
            1 
        } else if (type1 < type2) {
            2 
        }else{
            if(type1 == 2){
                let pair1 =  get_pair_value(hand1);
                let pair2 =  get_pair_value(hand2);
                if (pair1 > pair2) {
                    1 
                } else if (pair1 < pair2) {
                    2 
                }else{
                    get_high_cards(hand1,hand2)
                }
            }else{
                get_high_cards(hand1,hand2)
            }
        }

     }

     
    fun sub_vector(a: &vector<u8>, start: u64, length: u64): vector<u8> {
        let mut result = vector::empty<u8>();
        let mut i = start;
        while (i < length) {
            let elem = *vector::borrow(a, i);
            vector::push_back(&mut result, elem);
            i = i + 1;
        };
        result
    }


    fun result_cards(b:bool,opencards:vector<u8>,revealcards:vector<u8>):u8{
        if(b){
            let cards_p1 = show_cards(revealcards,opencards);
            let cards_p2 = show_cards(opencards,revealcards);
            compare_cards(cards_p1,cards_p2)
        }else{
            let cards_p1 = show_cards(opencards,revealcards);
            let cards_p2 = show_cards(revealcards,opencards);
            compare_cards(cards_p1,cards_p2)
        }
    }
    fun show_cards(cards1:vector<u8>,cards2:vector<u8>):vector<u8>{
        let mut cards =  vector::empty<u8>();
        vector::push_back(&mut cards,cards1[cards2[52] as u64]);
        vector::push_back(&mut cards,cards1[cards2[53] as u64]);
        vector::push_back(&mut cards,cards1[cards2[54] as u64]);
        cards
    }
   
    entry fun create_game(sigcards:vector<u8>,coin_v: Coin<SUI>,game_data: &mut GameData,ctx: &mut TxContext) {
        let coin_value = coin::value(&coin_v);
        assert!(coin_value >= game_data.min && coin_value <= game_data.max, EBetVol);
        game_data.gamenumber = game_data.gamenumber+1;
        // assert!(revealcard.length==2,ERev);
        let pokerdata = PokerData {
            id: object::new(ctx),
            balance: coin::into_balance(coin_v),
            player1:ctx.sender(), 
            player2:@0x0,
            sigcards1: sigcards,
            sigcards2: vector::empty<u8>(),
            revealcards1:vector::empty<u8>(),
            revealcards2:vector::empty<u8>(),
            stage:10,               
            bet:coin_value,
            time:0,
            action: false, 
        };
        dof::add(&mut game_data.id,game_data.gamenumber, pokerdata);
        emit(GnumberOpen{
            result:game_data.gamenumber,
            vol:coin_value,
        });
    }


    entry fun join_game(gamenumber: u64,sigcards:vector<u8>,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        let coin_value = coin::value(&coin_v);
        assert!(coin_value == pk_data.bet, EBetVol);
        assert!(pk_data.player2 == @0x0, EIngame);
        // assert!(revealcard.length==2,ERev);
        pk_data.player2 = ctx.sender();
        pk_data.sigcards2 = sigcards;
        pk_data.stage=0;             
        pk_data.time = clock.timestamp_ms();
        coin::put(&mut pk_data.balance, coin_v);
        emit(GnumberClose{
            result:gamenumber,
        });
    }
  
    fun apply_look_cards_(b:bool,revealcards:vector<u8>,clock:u64,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, EAction);
        assert!(vector::length(&revealcards) < 1, ERevealcards);
        *stage = 6;
        *time = clock;
        *action = b;
    }

    entry fun apply_look_cards(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 4, EStage);
        if(ctx.sender() == pk_data.player1){
            apply_look_cards_(true,pk_data.revealcards2,clock.timestamp_ms(),&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(ctx.sender() == pk_data.player2){
            apply_look_cards_(false,pk_data.revealcards1,clock.timestamp_ms(),&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        };
    }

    fun reveal_look_cards_(b:bool,revealcards:vector<u8>,clock:u64,revealcards_:&mut vector<u8>,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, EAction);
        assert!(stage == 6, EStage);
        // assert!(vector::length(revealcards_) < 1, ERevealcards);
        let ver3 = verification_cards3(&revealcards);
        assert!(ver3, ECardThree);
        *revealcards_ = revealcards;
        *time = clock;
        *action = b;
        *stage = 2;
    }


    entry fun reveal_look_cards(gamenumber:u64,revealcards:vector<u8>,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        assert!(vector::length(&revealcards)==3 ,ERevealcards);
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        if(ctx.sender() == pk_data.player1){
            reveal_look_cards_(true,revealcards,clock.timestamp_ms(),&mut pk_data.revealcards1,&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(ctx.sender() == pk_data.player2){
            reveal_look_cards_(false,revealcards,clock.timestamp_ms(),&mut pk_data.revealcards2,&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        };
        
    }
 
    fun call_(b:bool,revealcards:vector<u8>,coinv:u64,bet:u64,clock:u64,time:&mut u64,action:&mut bool){
        assert!(action != b, EAction);
        if(vector::length(&revealcards) < 1){
            assert!(coinv==bet/2, EBetVol);
        }else{
            assert!(coinv==bet, EBetVol);
        };
        *time = clock;
        *action = b;
    }

    entry fun call(gamenumber:u64,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(ctx.sender() == pk_data.player1 || ctx.sender() == pk_data.player2, ENotP);
        assert!(pk_data.stage < 4, EStage);
        let coin_value = coin::value(&coin_v);
        coin::put(&mut pk_data.balance, coin_v);
        if(ctx.sender() == pk_data.player1){
            call_(true,pk_data.revealcards2,coin_value,pk_data.bet,clock.timestamp_ms(),&mut pk_data.time,&mut pk_data.action);
        }else{
            call_(false,pk_data.revealcards1,coin_value,pk_data.bet,clock.timestamp_ms(),&mut pk_data.time,&mut pk_data.action);
        };
        emit(Gvol{
            vol:coin_value,
            player:ctx.sender(),
            expendORincome:false,
        });
    }


    fun rasie_(b:bool,revealcards:vector<u8>,coinv:u64,max:u64,clock:u64,bet:&mut u64,time:&mut u64,action:&mut bool){
        assert!(action != b, EAction);
        if(vector::length(&revealcards) < 1){
            assert!(coinv > *bet / 2, EBetVol);
            assert!(coinv <= max, EBetVol);
            *bet = coinv*2;
        }else{
            assert!(coinv > *bet, EBetVolBig);
            assert!(coinv <= max*2, EBetVolBig);
            *bet = coinv;
        };
        *time = clock;
        *action = b;
    }

    entry fun rasie(gamenumber:u64,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(ctx.sender() == pk_data.player1 || ctx.sender() == pk_data.player2, ENotP);
        assert!(pk_data.stage < 4, EStage);
        let coin_value = coin::value(&coin_v);
        coin::put(&mut pk_data.balance, coin_v);
        if(ctx.sender() == pk_data.player1){
            rasie_(true,pk_data.revealcards2,coin_value,game_data.max,clock.timestamp_ms(),&mut pk_data.bet,&mut pk_data.time,&mut pk_data.action);
        }else{
            rasie_(false,pk_data.revealcards1,coin_value,game_data.max,clock.timestamp_ms(),&mut pk_data.bet,&mut pk_data.time,&mut pk_data.action);
        };
        emit(Gvol{
            vol:coin_value,
            player:ctx.sender(),
            expendORincome:false,
        });
    }



    fun applyOpenCards_(b:bool,revealcards:vector<u8>,sigcards:vector<u8>,public_key:vector<u8>,
        opencards:vector<u8>,coinv:u64,clock: u64,bet:u64,revealcards_:&mut vector<u8>,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, EAction);
        if(vector::length(&revealcards) < 1){
            assert!(coinv==bet, EBetVol);
        }else{
            assert!(coinv==bet*2, EBetVol);
        };

        let is_sig_cards = bls12381_min_pk_verify(&sigcards, &public_key, &opencards);
        assert!(is_sig_cards, EInvalidBlsSig);
        let cards_3 = sub_vector(&opencards, 52, 55);
        if(vector::length(revealcards_)==3){
            let revealcard =  verification_reveal(revealcards_,&cards_3);
            assert!(revealcard, EOpencardsThree);
        }else{
            let ver3 = verification_cards3(&cards_3);
            assert!(ver3, ECardThree);
        };
        let cards_52 = sub_vector(&opencards, 0, 52);
        let ver52 = verification_cards52(&cards_52);
        assert!(ver52, ECard);
        *revealcards_ = opencards;
        *time = clock;
        *action = b;
        *stage = 4;
    }
    entry fun applyOpenCards(gamenumber: u64,opencards:vector<u8>,public_key:vector<u8>,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 4, EStage);
        let coin_value = coin::value(&coin_v);
        coin::put(&mut pk_data.balance, coin_v);
        assert!(vector::length(&opencards)==55 ,EOpencards);
        if(ctx.sender() == pk_data.player1){
            applyOpenCards_(true,pk_data.revealcards2,pk_data.sigcards1,public_key,
            opencards,coin_value,clock.timestamp_ms(),pk_data.bet,&mut pk_data.revealcards1,
            &mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(ctx.sender() == pk_data.player2){
            applyOpenCards_(false,pk_data.revealcards1,pk_data.sigcards2,public_key,
            opencards,coin_value,clock.timestamp_ms(),pk_data.bet,&mut pk_data.revealcards2,
            &mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        };
        emit(Gvol{
            vol:coin_value,
            player:ctx.sender(),
            expendORincome:false,
        });
    }


    fun OpenCards_(
        num: u8,
        b: bool,
        revealcards: vector<u8>,
        sigcards: vector<u8>,
        public_key: vector<u8>,
        opencards: vector<u8>,
        coinp:Coin<SUI>,
        revealcards_: vector<u8>,
        adder: address,
        shend: address,
        coinp_v:u64, 
        stage: &mut u8, 
        time: &mut u64, 
        action: bool,
    ){
        assert!(action != b, EAction);
        assert!(vector::length(&revealcards)==55, ERevealcards);
        let is_sig_cards = bls12381_min_pk_verify(&sigcards, &public_key, &opencards);
        assert!(is_sig_cards, EInvalidBlsSig);
        let cards_3 = sub_vector(&opencards, 52,55);
        if(vector::length(&revealcards_)==3){
            let revealcard =  verification_reveal(&revealcards_,&cards_3);
            assert!(revealcard, EOpencardsThree);
        }else{
            let ver3 = verification_cards3(&cards_3);
            assert!(ver3, ECardThree);
        };
        let cards_52 = sub_vector(&opencards, 0, 52);
        let ver52 = verification_cards52(&cards_52);
        assert!(ver52, ECard);

        let result = result_cards(action,opencards,revealcards);
      
        if(result == 0 || result == num){
            transfer::public_transfer(coinp,shend);
            if(num==1){
                *stage = 11; 
                *time = 0;
            }else{
                *stage = 12;
                *time = 0;
            };
            emit(Gvol{
                vol:coinp_v,
                player:shend,
                expendORincome:true,
            });
        }else{
            transfer::public_transfer(coinp,adder);
            if(num==1){
                *stage = 12; //这里控制继续游戏
                *time = 0;
            }else{
                *stage = 11;
                *time = 0;
            };
            emit(Gvol{
                vol:coinp_v,
                player:adder,
                expendORincome:true,
            });
        };
        
    }
    entry fun OpenCards(gamenumber: u64,opencards:vector<u8>,public_key:vector<u8>,game_data: &mut GameData,ctx: &mut TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage == 4, EStage);
        assert!(ctx.sender() == pk_data.player1 || ctx.sender() == pk_data.player2, ENotP);
        assert!(vector::length(&opencards)==55 ,EOpencards);
        
        let cvalue = balance::value(&pk_data.balance);
        let fee = cvalue/1000 * (game_data.fee as u64);
        let coina = coin::take(&mut pk_data.balance, fee, ctx);
        coin::put(&mut game_data.balance, coina);
        let cvaluep = cvalue-fee;
        let coinp = coin::take(&mut pk_data.balance, cvaluep , ctx);

        if(ctx.sender() == pk_data.player1){
            OpenCards_(1,true,pk_data.revealcards2,pk_data.sigcards1,public_key,
            opencards,coinp,pk_data.revealcards1,pk_data.player2,ctx.sender(),cvaluep,
             &mut pk_data.stage,&mut pk_data.time,pk_data.action);

        }else if(ctx.sender() == pk_data.player2){
            OpenCards_(2,false,pk_data.revealcards1,pk_data.sigcards2,public_key,
            opencards,coinp,pk_data.revealcards2,pk_data.player1,ctx.sender(),cvaluep,
             &mut pk_data.stage,&mut pk_data.time, pk_data.action);
        }else {
        // If neither condition is met, make sure to transfer the coinp to avoid unused value error
            coin::put(&mut pk_data.balance, coinp);
        }
    }


     
    fun fold_(b:bool,clock: u64,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, EAction);
        *time = clock;
        *action = b;
        *stage = 5;
    }

    entry  fun fold(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 5, EStage);
        if(ctx.sender() == pk_data.player1){
            fold_(true,clock.timestamp_ms(),&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(ctx.sender() == pk_data.player2){
            fold_(false,clock.timestamp_ms(),&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }
    }



 
    fun get_fold_bets_(b:bool,action:bool,sigcards:vector<u8>,public_key:vector<u8>,
        opencards:vector<u8>,coinp:Coin<SUI>,revealcards_:vector<u8>,cvaluep:u64,
        stage:&mut u8,time:&mut u64,sand:address){
        assert!(action != b, EAction);
        let is_sig_cards = bls12381_min_pk_verify(&sigcards, &public_key, &opencards);
        assert!(is_sig_cards, EInvalidBlsSig);

        if(vector::length(&revealcards_)==3){
            let cards_3 = sub_vector(&opencards, 52, 55);
            let revealcard =  verification_reveal(&revealcards_,&cards_3);
            assert!(revealcard, EOpencardsThree);
        };
        let cards_52 = sub_vector(&opencards, 0, 52);
        let ver52 = verification_cards52(&cards_52);
        assert!(ver52, ECard);
        transfer::public_transfer(coinp,sand);
        if(b){
            *stage = 11;
            *time = 0;
        }else{
            *stage = 12;
            *time = 0;
        };
        emit(Gvol{
            vol:cvaluep,
            player:sand,
            expendORincome:true,
        });
        
    }
    entry fun get_fold_bets(gamenumber: u64,opencards:vector<u8>,public_key:vector<u8>,game_data: &mut GameData,ctx: &mut TxContext){
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(ctx.sender() == pk_data.player1 || ctx.sender() == pk_data.player2, ENotP);
        assert!(pk_data.stage == 5, EStage);
        let cvalue = balance::value(&pk_data.balance);
        let fee = cvalue/1000 * (game_data.fee as u64);
        let coina = coin::take(&mut pk_data.balance, fee, ctx);
        coin::put(&mut game_data.balance, coina);
        let cvaluep = cvalue-fee;
        let coinp = coin::take(&mut pk_data.balance, cvaluep , ctx);
        if(ctx.sender() == pk_data.player1){
            get_fold_bets_(true,pk_data.action,pk_data.sigcards1,public_key,opencards,
            coinp,pk_data.revealcards1,cvaluep,&mut pk_data.stage,&mut pk_data.time,ctx.sender());
        }else if(ctx.sender() == pk_data.player2){
            get_fold_bets_(false,pk_data.action,pk_data.sigcards2,public_key,opencards,
            coinp,pk_data.revealcards2,cvaluep,&mut pk_data.stage,&mut pk_data.time,ctx.sender());
        }else{
        // If neither condition is met, make sure to transfer the coinp to avoid unused value error
            coin::put(&mut pk_data.balance, coinp);
        }
    }
  
    entry fun get_timeout_bets(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext){
        let PokerData{
            id,
            mut balance,
            player1,
            player2,
            sigcards1: _,
            sigcards2: _,
            revealcards1:_,
            revealcards2:_,
            stage:_,
            bet:_,
            time,
            action,
        }= dof::remove(&mut game_data.id,gamenumber);
        let ctime = clock.timestamp_ms()-game_data.countdown;
        assert!(time > 0 && ctime > time, ETime);
        let cvalue = balance::value(&balance);
        let fee = cvalue/1000 * (game_data.fee as u64);
        let coina = coin::take(&mut balance, fee, ctx);
        coin::put(&mut game_data.balance, coina);
        let cvaluep = cvalue-fee;
        let coinp = coin::take(&mut balance, cvaluep , ctx);
        if(action){
            transfer::public_transfer(coinp,player1);
            emit(Gvol{
                vol:cvaluep,
                player:player1,
                expendORincome:true,
            });
        }else{
            transfer::public_transfer(coinp,player2);
            emit(Gvol{
                vol:cvaluep,
                player:player2,
                expendORincome:true,
            });
        };
        balance::destroy_zero(balance);
        object::delete(id);
        emit(GnumberClose{
            result:gamenumber,
        });

        
    }

    entry fun go_on_playing(gamenumber: u64,sigcards:vector<u8>,coin_v: Coin<SUI>,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(ctx.sender() == pk_data.player1 || ctx.sender() == pk_data.player2, EPlayer);
        assert!(pk_data.stage == 11 || pk_data.stage == 12, EStage);
        let coin_value = coin::value(&coin_v);
        assert!(coin_value >= game_data.min && coin_value <= game_data.max, EBetVol);
        coin::put(&mut pk_data.balance, coin_v);
        if(pk_data.stage == 11){
            if(ctx.sender() == pk_data.player1){
                pk_data.player2 = ctx.sender();
                pk_data.player1 = @0x0;
                pk_data.sigcards2 = sigcards;
                pk_data.sigcards1 = vector::empty<u8>();
            }else{
                pk_data.player1 = ctx.sender();
                pk_data.player2 = @0x0;
                pk_data.sigcards1 = sigcards;
                pk_data.sigcards2 = vector::empty<u8>();
            };
        }else{
            if(ctx.sender() == pk_data.player1){
                pk_data.player2 =  @0x0;
                pk_data.sigcards1 = sigcards;
                pk_data.sigcards2 = vector::empty<u8>();
            }else{
                pk_data.player1 = @0x0;
                pk_data.sigcards2 = sigcards;
                pk_data.sigcards1=vector::empty<u8>();
            };
        };
        pk_data.revealcards1=vector::empty<u8>();
        pk_data.revealcards2=vector::empty<u8>();
        pk_data.bet=coin_value;
        pk_data.action = false;
        pk_data.stage = 10; 
        emit(GnumberCont{
            result:gamenumber,
            vol:coin_value,
        });
    }
 
    entry fun join_playing(gamenumber: u64,sigcards:vector<u8>,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &TxContext) {
        let pk_data: &mut PokerData = dof::borrow_mut(&mut game_data.id,gamenumber);
        let coin_value = coin::value(&coin_v);
        assert!(coin_value == pk_data.bet, EBetVol);
        assert!(pk_data.player2 == @0x0 || pk_data.player1 == @0x0, EIngame);
        // assert!(revealcard.length==2,ERev);
        if(pk_data.player2 == @0x0 ){
            pk_data.player2 = ctx.sender();
            pk_data.sigcards2 = sigcards;
        }else{
            pk_data.player1 = ctx.sender();
            pk_data.sigcards1 = sigcards;
        };
        pk_data.stage=0;             
        pk_data.time = clock.timestamp_ms();
        coin::put(&mut pk_data.balance, coin_v);
        emit(GnumberClose{
            result:gamenumber,
        });
    }

    entry fun leave_game(gamenumber: u64,game_data: &mut GameData,ctx: &mut TxContext){
        let PokerData{
            id,
            mut balance,
            player1,
            player2,
            sigcards1: _,
            sigcards2: _,
            revealcards1:_,
            revealcards2:_,
            stage,
            bet:_,
            time:_,
            action:_,
        }= dof::remove(&mut game_data.id,gamenumber);
        assert!(ctx.sender() == player1 || ctx.sender() == player2 || ctx.sender() == Adminadd, EPlayer);
        assert!(stage == 10 || stage == 11 || stage == 12, EStage);
        if(stage == 10 ){
            let cvalue = balance::value(&balance);
            let coinp = coin::take(&mut balance, cvalue, ctx);
            if(player1 != @0x0){
                transfer::public_transfer(coinp,player1);
            }else{
                transfer::public_transfer(coinp,player2);
            }
        };
        balance::destroy_zero(balance);
        object::delete(id);
        emit(GnumberClose{
            result:gamenumber,
        });
    }
   public  fun test(a:vector<u8>,b:vector<u8>){
        let aaa = result_cards(true,a,b);
        emit(Testout{
            result:aaa,
        });
    }
}
