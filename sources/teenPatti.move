


module suiwin::suiwin {
    use sui::event::emit;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use sui::hash::blake2b256;
    use sui::dynamic_object_field as dof;
    use std::vector;
    

    const EInGame: u64 = 0;
    const EAdmin: u64 =1;
    const ENotBet:u64 = 2;
    const EgiveoutprizesT:u64= 3;
    const EgiveoutprizesB:u64 = 4;
    const EVol:u64 = 5;
    const EGameing: u64 = 6;
    const ERev: u64 = 7;
    const EFold:u64 = 8;
    const EAdd:u64 = 9;
    const EInvalidBlsSig = 10;
    const Ehonest=11;
    const EBet=12;
    const EWithdrawallockORpklock = 13;
    const EFee = 14;
    const ECountdown = 15;
    const ELook = 16;



    const Adminadd: address = @0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44;


    public struct GameData has key {
        id: UID,
        fee:u8,
        countdown:u16,
        min:u64,
        max:u64,
        gamenumber:u64,
        
    }
    

    public struct WLock has key{
        id: UID,
        data: u64,

    }
    public struct AdminCap has key ,store{ id: UID }

    //dof::add(&mut game.id,serialnumber, gPlayer);
    

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



    public entry fun change_WL(_: &AdminCap,wl:&mut WLock,ctx: &mut TxContext){
        wl.data = tx_context::epoch(ctx);

    }

    public entry fun change_data_fee(_: &AdminCap,fee:u64,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        assert!(fee < 51,EFee);
        gamedata.fee=fee;
        wl.data = 9999999;
    }
    public entry fun change_data_countdown_down(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.countdown = gamedata.countdown - 10000;
        assert!(gamedata.countdown > 20_000,EWithdrawallockORpklock);
        wl.data = 9999999;
    }
    public entry fun change_data_countdown_up(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.countdown = gamedata.countdown + 10000;
        assert!(gamedata.countdown < 120_000,EWithdrawallockORpklock);
        wl.data = 9999999;
    }


    public entry fun change_data_min_down(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.min = gamedata.min/2;
        assert!(gamedata.min > 100_000_000,EWithdrawallockORpklock);
        wl.data = 9999999;
    }
    public entry fun change_data_min_up(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.min = gamedata.min * 2;
        assert!(gamedata.min < 55_000_000_000,EWithdrawallockORpklock);
        wl.data = 9999999;
    }


    public entry fun change_data_max_down(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.max = gamedata.max/2;
        assert!(gamedata.max > 100_000_000_000,EWithdrawallockORpklock);
        wl.data = 9999999;
    }
    public entry fun change_data_max_up(_: &AdminCap,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        gamedata.max = gamedata.max*2;
        assert!(gamedata.max < 1_000_000_000_000_000,EWithdrawallockORpklock);
        wl.data = 9999999;
    }

    


    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::share_object(GameData {
            id: object::new(ctx),
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
        let mut j = 1;
        while (j < 53) {
            let ver = vector::contains(&list, j);
            if (!ver) {
                return false;
            }
            j = j + 1;
        }
        return true;
    }

    fun verification_cards3(list: &vector<u8>): bool {
        let num1 = list[0];
        let num2 = list[1];
        let num3 = list[2];
        if (num1 == num2 || num1 == num3 || num2 == num3) {
            return false;
        }
        if (num1 > 51 ||num2 > 51 ||  num > 51) {
            return false;
        }
        return true;
        
    }

    fun verification_reveal(a: &vector<u8>, b: &vector<u8>): bool {

        let mut i = 0;
        while (i < 3) {
            if (a[i] != b[i]) {
                return false;
            }
            i = i + 1;
        }

        return true;
    }








    fun get_high_cards(hand1: vector<u8>, hand2: vector<u8>): u8 {

        let mut value1 = get_values(hand1);
        let mut value2 = get_values(hand2);
        let mut values1 = handle_special_case(value1);
        let mut values2 = handle_special_case(value2);

  
        values1.sort3();
        values2.sort3();


        let mut i = 2;
        while (i >= 0) {
            if (values1[i] > values2[i]) {
                return 1; 
            } else if (values1[i] > values2[i]) {
                return 2; 
            }
            if (i == 0) {
                break;
            }
            i = i - 1;
    
        }

 
        return 0;
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
            }
            i = i + 1;
        }
        return result;
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
   
        if (v[0] > * v[1]) {
            vector::swap(v, 0, 1);
        };

 
        if (v[1] > v[2]) {
            vector::swap(v, 1, 2);
        };

   
        if (v[0] > v[1]) {
            vector::swap(v, 0, 1);
        }
    }

    fun compare_cards(hand1: vector<u8>, hand2: vector<u8>): u8 {
        let type1 = get_cards_type(hand1);
        let type2 = get_cards_type(hand2);
        if (type1 > type2) {
            return 1; 
        } else if (type1 < type2) {
            return 2; 
        }else{
            get_high_cards(hand1,hand2)
        }

     }

    entry fun create_game(sigcards:vector<u8>,coin_v: Coin<SUI>,game_data: &mut GameData,ctx: &mut TxContext) {
        let coin_value = coin::value(&coin_v);
        assert!(coin_value >= game_data.min && coin_value <= game_data.max, ENotBet)
        game_data.gamenumber = game_data.gamenumber+1;
        // assert!(revealcard.length==2,ERev);
        let pokerdata = PokerData {
            id: object::new(ctx),
            balance: coin::into_balance(coin_v),
            player1:tx_context::sender(ctx),
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
    }


    entry fun join_game(gamenumber: u64,sigcards:vector<u8>,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        let coin_value = coin::value(&coin_v);
        assert!(coin_value == pk_data.bet, ENotBet);
        assert!(pk_data.player2 == @0x0, EIngame);
        // assert!(revealcard.length==2,ERev);
        pk_data.player2 = tx_context::sender(ctx);
        pk_data.sigcards2 = sigcards;
        pk_data.stage=0;             
        pk_data.time = clock.timestamp_ms();
        coin::put(&mut pk_data.balance, coin_v);
    }
 
    fun _apply_look_cards(num:u8,b:bool,revealcards:vector<u8>,clock: &Clock,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, ELook);
        assert!(vector::length(revealcards) < 1, ELook);
        assert!(stage != num, ELook);
        if(stage == 0){
            *stage = num;
        }else{
            *stage = 3;
        }
        *time = clock.timestamp_ms();
        *action = b;
    }

    entry fun apply_look_cards(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 3, ELook);
        if(tx_context::sender(ctx) == pk_data.player1){
            _apply_look_cards(1,true,pk_data.revealcards2,&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _apply_look_cards(2,false,pk_data.revealcards1,&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }
    }

    fun _reveal_look_cards(num:u8,b:bool,revealcards:vector<u8>,clock: &Clock,revealcards_:&mut vector<u8>,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, ELook);
        assert!(stage == num || stage == 3, ELook);
        assert!(vector::length(revealcards1) < 1, ELook);
        *revealcards_ = revealcards;
        *time = clock.timestamp_ms();
        *action = b;
    }


    entry fun reveal_look_cards(gamenumber:u64,revealcards:vector<u8>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        assert!(vector::length(revealcards)==3 ,ELook);
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        if(tx_context::sender(ctx) == pk_data.player1){
            _reveal_look_cards(2,true,revealcards,clock,&mut pk_data.revealcards1,&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _reveal_look_cards(1,false,revealcards,clock,&mut pk_data.revealcards2,&mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }
    }

    fun _call(b:bool,revealcards:vector<u8>,coinv:u64,bet:u64,clock: &Clock,time:&mut u64,action:&mut bool){
        assert!(action != b, ELook);
        if(vector::length(revealcards) < 1){
            assert!(coinv>=bet/2, ELook);
        }else{
            assert!(coinv>=bet, ELook);
        };
        *time = clock.timestamp_ms();
        *action = b;
    }

    entry fun call(gamenumber:u64,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 4, ELook);
        let coin_value = coin::value(&coin_v);
        coin::put(&mut pk_data.balance, coin_v);
        if(tx_context::sender(ctx) == pk_data.player1){
            _call(true,pk_data.revealcards2,coin_value,pk_data.bet,&mut pk_data.time,&mut pk_data.action);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _call(false,pk_data.revealcards1,coin_value,pk_data.bet,&mut pk_data.time,&mut pk_data.action);
        }
    }



    fun _rasie(b:bool,revealcards:vector<u8>,coinv:u64,max:u64,clock: &Clock,bet:&mut u64,time:&mut u64,action:&mut bool){
        assert!(action != b, ELook);
        if(vector::length(revealcards) < 1){
            assert!(coinv > bet/2, ELook);
            assert!(coinv <= max, ENotBet)
            *bet = coinv*2;
        }else{
            assert!(coinv>bet, ELook);
            assert!(coinv <= max*2, ENotBet)
            *bet = coinv;
        };
        *time = clock.timestamp_ms();
        *action = b;
    }

    entry fun rasie(gamenumber:u64,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 4, ELook);
        let coin_value = coin::value(&coin_v);
        coin::put(&mut pk_data.balance, coin_v);
        if(tx_context::sender(ctx) == pk_data.player1){
            _rasie(true,pk_data.revealcards2,coin_value,game_data.max,clock,&mut pk_data.bet,&mut pk_data.time,&mut pk_data.action);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _rasie(false,pk_data.revealcards1,coin_value,game_data.max,clock,&mut pk_data.bet,&mut pk_data.time,&mut pk_data.action);
        }
    }


 
    fun _applyOpenCards(b:bool,revealcards:vector<u8>,sigcards:vector<u8>,public_key:vector<u8>,
        opencards:vector<u8>,coinv:u64,max:u64,clock: &Clock,bet:u64,&mut revealcards_:vector<u8>,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, ELook);
        if(vector::length(revealcards) < 1){
            assert!(coinv>=bet, ELook);
        }else{
            assert!(coinv>=bet*2, ELook);
        };

        let is_sig_cards = bls12381_min_pk_verify(&sigcards, &public_key, &opencards);
        assert!(is_sig_cards, EInvalidBlsSig);
        let start_index = vector::length(opencards) - 3;
        let cards_3 = vector::sub_vector(opencards, start_index, 3);
        let ver3 = verification_cards3(cards_3);
        assert!(ver3, ELook);
        if(vector::length(revealcards_)==3){
            let revealcard =  verification_reveal(revealcards_,cards_3)
            assert!(revealcard, ELook);
        }
        let cards_52 = vector::sub_vector(opencards, 0, 52);
        let ver52 = verification_cards52(cards_52);
        assert!(ver52, ELook);
        *revealcards_ = opencards;
        *time = clock.timestamp_ms();
        *action = b;
        *stage = 4;
    }
    entry fun applyOpenCards(gamenumber: u64,opencards:vector<u8>,public_key:vector<u8>,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 4, ELook);
        let coin_value = coin::value(&coin_v);
        coin::put(&mut pk_data.balance, coin_v);
        assert!(vector::length(opencards)==55 ,ELook);
        if(tx_context::sender(ctx) == pk_data.player1){
            _applyOpenCards(true,pk_data.revealcards2,pk_data.sigcards1,public_key,
            opencards,coin_value,clock,pk_data.bet,&mut pk_data.revealcards1,
            &mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _applyOpenCards(false,pk_data.revealcards1,pk_data.sigcards2,public_key,
            opencards,coin_value,clock,pk_data.bet,&mut pk_data.revealcards2,
            &mut pk_data.stage,&mut pk_data.time,&mut pk_data.action);
        }
    }
   

    fun _OpenCards(num:u8,b:bool,revealcards:vector<u8>,sigcards:vector<u8>,public_key:vector<u8>,
        opencards:vector<u8>,coinp:Coin<SUI>,clock: &Clock,revealcards_:vector<u8>,adder:address,
        stage:&mut u8,time:&mut u64,action:bool,ctx: &mut TxContext){
        assert!(action != b, ELook);
        assert!(vector::length(revealcards)==55, ELook);
        let is_sig_cards = bls12381_min_pk_verify(&sigcards, &public_key, &opencards);
        assert!(is_sig_cards, EInvalidBlsSig);
        let start_index = vector::length(opencards) - 3;
        let cards_3 = vector::sub_vector(opencards, start_index, 3);
        let ver3 = verification_cards3(cards_3);
        assert!(ver3, ELook);
        if(vector::length(revealcards_)==3){
            let revealcard =  verification_reveal(revealcards_,cards_3)
            assert!(revealcard, ELook);
        }
        let cards_52 = vector::sub_vector(opencards, 0, 52);
        let ver52 = verification_cards52(cards_52);
        assert!(ver52, ELook);
        let mut cards_p1 = vector::empty<u8>();
        let mut cards_p2 = vector::empty<u8>();

        cards_p1[0] = opencards[revealcards[52]];
        cards_p1[1] = opencards[revealcards[53]];
        cards_p1[2] = opencards[revealcards[54]];
        cards_p2[0] = revealcards[opencards[52]];
        cards_p2[1] = revealcards[opencards[53]];
        cards_p2[2] = revealcards[opencards[54]];
        let result = compare_cards(cards_p1,cards_p2);
        if(result == 0 || result == num){
            transfer::public_transfer(coinp,tx_context::sender(ctx));
            if(num==1){
                *stage = 11; 
            }else{
                *stage = 12;
            }
        }else{
            transfer::public_transfer(coinp,adder);
            if(num==1){
                *stage = 12; 
            }else{
                *stage = 11;
            }
        }
        *time = 0;
    
    }
    entry fun OpenCards(gamenumber: u64,opencards:vector<u8>,public_key:vector<u8>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage == 4, ELook);
        assert!(vector::length(opencards)==55 ,ELook);


        let cvalue = coin::value(&pk_data.balance);
        let fee = cvalue/1000 * game_data.fee;
        let coina = coin::take(&mut pk_data.balance, fee, ctx);
        transfer::public_transfer(coina,Adminadd);
        let coinp =  coin::from_balance(&mut pk_data.balance,ctx);

        if(tx_context::sender(ctx) == pk_data.player1){
            _OpenCards(1,true,pk_data.revealcards2,pk_data.sigcards1,public_key,
            opencards,coinp,clock,pk_data.revealcards1,pk_data.player2,
             &mut pk_data.stage,&mut pk_data.time,pk_data.action,&mut ctx);

        }else if(tx_context::sender(ctx) == pk_data.player2){
            _OpenCards(2,false,pk_data.revealcards1,pk_data.sigcards2,public_key,
            opencards,coinp,clock,pk_data.revealcards2,pk_data.player1,
             &mut pk_data.stage,&mut pk_data.time, pk_data.action,&mut ctx);
        }
    }


 
    fun _fold(b:bool,clock: &Clock,stage:&mut u8,time:&mut u64,action:&mut bool){
        assert!(action != b, ELook);
        *time = clock.timestamp_ms();
        *action = b;
        *stage = 5;
    }
    entry  fun fold(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage < 5, ELook);
        if(tx_context::sender(ctx) == pk_data.player1){
            _fold(true,pk_data.stage,pk_data.time,pk_data.action);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _fold(false,pk_data.stage,pk_data.time,pk_data.action);
        }
    }




    fun _get_fold_bets(b:bool,sigcards:vector<u8>,public_key:vector<u8>,
        opencards:vector<u8>,coinp:Coin<SUI>,revealcards_:vector<u8>,
        stage:&mut u8,time:&mut u64,ctx: &mut TxContext){
        let is_sig_cards = bls12381_min_pk_verify(&sigcards, &public_key, &opencards);
        assert!(is_sig_cards, EInvalidBlsSig);
        let start_index = vector::length(opencards) - 3;
        let cards_3 = vector::sub_vector(opencards, start_index, 3);
        let ver3 = verification_cards3(cards_3);
        assert!(ver3, ELook);
        if(vector::length(revealcards_)==3){
            let revealcard =  verification_reveal(revealcards_,cards_3)
            assert!(revealcard, ELook);
        }
        let cards_52 = vector::sub_vector(opencards, 0, 52);
        let ver52 = verification_cards52(cards_52);
        assert!(ver52, ELook);
        transfer::public_transfer(coinp,tx_context::sender(ctx));
        if(b){
            *stage = 11;
        }else{
            *stage = 12;
        }
        *time = 0;
    }
    entry fun get_fold_bets(gamenumber: u64,opencards:vector<u8>,public_key:vector<u8>,game_data: &mut GameData,ctx: &mut TxContext){
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(pk_data.stage == 5, ELook);
        let cvalue = coin::value(&pk_data.balance);
        let fee = cvalue/1000 * game_data.fee;
        let coina = coin::take(&mut pk_data.balance, fee, ctx);
        transfer::public_transfer(coina,Adminadd);
        let coinp =  coin::from_balance(&mut pk_data.balance,ctx);
        if(tx_context::sender(ctx) == pk_data.player1){
            _get_fold_bets(true,pk_data.sigcards1,public_key,opencards,
            coinp,pk_data.revealcards1,pk_data.stage,pk_data.time,ctx);
        }else if(tx_context::sender(ctx) == pk_data.player2){
            _get_fold_bets(false,pk_data.sigcards2,public_key,opencards,
            coinp,pk_data.revealcards2,pk_data.stage,pk_data.time,ctx);
        }
    }

    entry fun get_timeout_bets(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext){
        let PokerData{
            id,
            balance,
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
        assert!(time > 0 && ctime > time, ELook);
        let cvalue = coin::value(balance);
        let fee = cvalue/1000 * game_data.fee;
        let coina = coin::take(&mut balance, fee, ctx);
        transfer::public_transfer(coina,Adminadd);
        let coinp =  coin::from_balance(&mut pk_data.balance,ctx);
        if(action){
            transfer::public_transfer(coinp,player1);
        }else{
            transfer::public_transfer(coinp,player2);
        };
        balance::destroy_zero(balance);
        object::delete(id);
    }


    entry fun go_on_playing(gamenumber: u64,sigcards:vector<u8>,coin_v: Coin<SUI>,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        assert!(tx_context::sender(ctx) == pk_data.player1 || tx_context::sender(ctx) == pk_data.player2, ENotBet);
        assert!(pk_data.stage == 11 || pk_data.stage == 12, ENotBet);
        let coin_value = coin::value(&coin_v);
        assert!(coin_value >= game_data.min && coin_value <= game_data.max, ENotBet);
        coin::put(&mut pk_data.balance, coin_v);
        if(pk_data.stage == 11){
            if(tx_context::sender(ctx) == pk_data.player1){
                pk_data.player2 = tx_context::sender(ctx);
                pk_data.player1 = @0x0;
                pk_data.sigcards2 = sigcards,
                pk_data.sigcards1: vector::empty<u8>(),
            }else{
                pk_data.player1 = tx_context::sender(ctx);
                pk_data.player2 = @0x0;
                pk_data.sigcards1 = sigcards,
                pk_data.sigcards2: vector::empty<u8>(),
            }
        }else{
            if(tx_context::sender(ctx) == pk_data.player1){
                pk_data.player2 =  @0x0;
                pk_data.sigcards1 = sigcards,
                pk_data.sigcards2 = vector::empty<u8>(),
            }else{
                pk_data.player1 = @0x0;
                pk_data.sigcards2 = sigcards;
                pk_data.sigcards1=vector::empty<u8>(),
            }
        }
        pk_data.revealcards1=vector::empty<u8>(),
        pk_data.revealcards2=vector::empty<u8>(),
        pk_data.bet=coin_value,
        pk_data.action = false,
        pk_data.stage = 10,  
    }
    
    entry fun join_playing(gamenumber: u64,sigcards:vector<u8>,coin_v: Coin<SUI>,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext) {
        let mut pk_data = dof::borrow_mut(&mut game_data.id,gamenumber);
        let coin_value = coin::value(&coin_v);
        assert!(coin_value == pk_data.bet, ENotBet);
        assert!(pk_data.player2 == @0x0 || pk_data.player1 == @0x0, EIngame);
        // assert!(revealcard.length==2,ERev);
        if(pk_data.player2 == @0x0 ){
            pk_data.player2 = tx_context::sender(ctx);
            pk_data.sigcards2 = sigcards;
        }else{
            pk_data.player1 = tx_context::sender(ctx);
            pk_data.sigcards1 = sigcards;
        }
        pk_data.stage=0;               
        pk_data.time = clock.timestamp_ms();
        coin::put(&mut pk_data.balance, coin_v);
    }

    entry fun leave_game(gamenumber: u64,clock: &Clock,game_data: &mut GameData,ctx: &mut TxContext){
        let PokerData{
            id,
            balance,
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
        assert!(tx_context::sender(ctx) == player1 || tx_context::sender(ctx) == player2 || tx_context::sender(ctx) == Adminadd, ENotBet);
        assert!(stage == 10 || stage == 11 || stage == 12, ENotBet);
        if(stage == 10 ){
            let coinp = coin::from_balance(&mut balance,ctx);
            if(player1 != @0x0){
                transfer::public_transfer(coinp,player1);
            }else{
                transfer::public_transfer(coinp,player2);
            }
        }
        balance::destroy_zero(balance);
        object::delete(id);
    }

}
