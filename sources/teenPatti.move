module suiwin::suiwin {
    use sui::random::{Self, Random};
    use sui::event::emit;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::table::{Table, Self};
    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use std::vector;
    use std::string::{Self, String};
    use sui::dynamic_object_field as dof;

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
    const EIngame = 16;

    const Adminadd: address = @0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44;


    public struct GameData has key {
        id: UID,
        fee:u8,
        countdown:u16,
        min:u64,
        max:u64,
        max2:u64,
        gamenumber:u64,
        ingame:bool,
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
        blind:u8,
        bet:u64,
        time:u64,
        action: bool,
    }



    public entry fun change_WL(_: &AdminCap,wl:&mut WLock,ctx: &mut TxContext){
        wl.data = tx_context::epoch(ctx);

    }

    public entry fun change_data(_: &AdminCap,fee:u64,countdown:u64,min:u64,max:u64,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        assert!(fee < 50,EFee);
        assert!(countdown > 20_000,EWithdrawallockORpklock);
        assert!(!gamedata.ingame,EIngame);

        gamedata.fee=fee;
        gamedata.countdown=countdown;
        gamedata.min=min;
        gamedata.max=max;
        gamedata.max2=max*2;
        wl.data = 9999999;
    }

    
    public entry fun delete_game(_: &AdminCap,id:ID,gamedata:&mut GameData,wl:&mut WLock,ctx:&mut TxContext){
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
        assert!(tx_context::epoch(ctx)>wl.data,EWithdrawallockORpklock);
       //...............................
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
            max:300_000_000_000,
            max2:600_000_000_000,,
            gamenumber:0,
            ingame:false,
        });
        transfer::share_object(WLock {
            id: object::new(ctx),
            data:9999999,
        });
    }


   

    entry  fun create_game(game_data: &mut GameData,sigcards:vector<u8>,coin_v: Coin<SUI>,ctx: &mut TxContext) {
        let coin_value = coin::value(&coin_v);
        assert!(coin_value >= game_data.min && coin_value <= game_data.max, ENotBet)
        game_data.gamenumber = game_data.gamenumber+1;
        game_data.ingame = true;

        let pokerdata = PokerData {
            id: object::new(ctx),
            balance: coin::into_balance(coin_v),
            player1:tx_context::sender(ctx),
            player2:@0x0,
            sigcards1: sigcards,
            sigcards2: vector::empty<u8>(),
            revealcards1:vector::empty<u8>(),
            revealcards2:vector::empty<u8>(),
            blind:0,              
            bet:coin_value,
            time:0,
            action: false, 
        };
        dof::add(&mut game_data.id,game_data.gamenumber, pokerdata);
    }



   

}
