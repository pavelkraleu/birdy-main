pragma solidity ^0.4.20;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/*
 * @title Birdy - the incentivised birdfeeder  
 * @dev This contract is handled by the arduino powered birdfeeder, the users & us as admins
 * @author Pavel Kral - project author
 * @author Josef Jelacic - solidity dev
 */
contract Birdy is Ownable{
    using SafeMath for uint256;

    // Birds related vars
    address public feeder;
    address public breeder;
    uint256 public timeChanged; //TODO: choose smaller uint type
    uint256 public minTime; 
    uint256 public birdsSince;
    uint256 public birdsTotal;
    uint256 public donorsCounter;
    uint256 public weiDonated;
    uint256 public payPerBird;
    
    // Breeders related mapping
    mapping (bytes32 => address) uids;
    mapping (address => uint256) streak;
    // Donations related mappings
    mapping (address => uint256) donated;
    mapping (uint256 => address) donorsList;

    /*
     * SECTION >>>> EVENTS
     */
    event newDonor (address indexed donor);
    event newDonation (address indexed donor, uint256 weiDonated);
    event birdsUpdated(uint256 newBirds);
    event paidOut (address indexed breeder, uint256 amount);
    event breederChanged (address indexed breeder);
    event payoutChanged (uint256 payout);
    event uidRegistered (bytes32 indexed uid, address indexed breeder);
    event feederChanged (address feeder);
    event minTimeChanged (uint256 minTime); 

    /*
     * @dev Modifier enabling function calls only to the feeder device
     */
    modifier onlyFeeder() {
        require(msg.sender == feeder);
        _;
    }

    /*
     * @dev Constructor setting up the feeder, price per visiting bird ...
     * @dev ... & minimal time interval to change a breeder 
     */
    function Birdy() public {
        feeder = msg.sender;
        payPerBird = 100 wei;
        minTime = 60; 
    }

    
    /*
     * @dev Fallback function which servers as a donation point 
     * (simply send some ether to be remebered as a hero!)
     */
    function () payable public {
        require(msg.value > 0);
        if (donated[tx.origin] == 0) {
            donorsList[donorsCounter] = tx.origin;
            donorsCounter += 1; // Could potentially overflow, but that's ok
            newDonor(tx.origin);
        }
        weiDonated += msg.value; // Could potentially overflow, but that's ok. I hope it will!
        donated[tx.origin] += msg.value; // Could potentially overflow, but that's ok. I hope it will!
        newDonation(tx.origin, msg.value);
    }

    /*
     * @dev Function which changes the current breeder and pays out the last known.
     * @dev It doesn't allow the same person to re-ender & a minimal time check has to be passed.
     * @dev Is called by the birdfeeder directly .
     * @param bytes32 _uid will be loaded from your NFC device 
     */
    function changeBreeder(bytes32 _uid) public onlyFeeder {
        uint256 timeDiff = now - timeChanged;
        address newBreeder = uids[_uid];

        require (timeDiff >= minTime);
        require (breeder != newBreeder);
        require (newBreeder != address(0));

        payOut();

        streak[breeder] += timeDiff;
        breeder = newBreeder;
        timeChanged = now;

        breederChanged(newBreeder);
    }

    /*
     * @dev Function which increases the number of birds that visited the feeder.
     * @dev Is called by the birdfeeder periodically.
     * @param uint256 birds - the number of birds visiting the feeder withing a given period
     */
    function iterateBirds(uint256 birds) public onlyFeeder {
        birdsSince += birds;
        birdsTotal += birds;
        birdsUpdated(birds);
    }

    /*
     * @dev Function which pays out the breeder per each bird or the whole balance. 
     * @dev Is called by the birdfeeder periodically or when the breeder change is initiated. 
     */
    function payOut() public onlyFeeder {
        uint256 payout = birdsSince.mul(payPerBird);
        uint256 balance = this.balance; 
        
        birdsSince = 0;
        
        if (balance >= payout) {
            breeder.transfer(payout);
        } else {
            breeder.transfer(balance);
        }
        
        paidOut(breeder, payout);
    }

    /*
     * @dev Function enabling UID (breeder) registration for future interaction with the breeder.
     * @dev Anyone can call it for a non-stored UID
     * @param bytes32 _uid of the NFC device
     * @param address _address of the UID owner
     */
    function registerUID(bytes32 _uid, address _address) public {
        require(uids[_uid] == address(0));
        uids[_uid] = _address;
        uidRegistered(_uid, _address);
    }
    
    /*
     * SECTION >>>> SETTINGS
     */
     
    /*
     * @dev Function to change the default value per visiting bird to be paid out.
     * @dev Can only be called by the contract owner (us).
     * @param uint256 _new - the new amount of wei to be paid for each bird
     */
    function changePayout(uint256 _new) public onlyOwner {
        payPerBird = _new;
        payoutChanged(_new);
    }

    /*
     * @dev Function to change address associated with the birdfeeder. 
     * @dev Can only be called by the contract owner (us).
     * @param address _new - the new address of used by the birdfeeder 
     */
    function changeFeeder(address _new) public onlyOwner {
        feeder = _new;
        feederChanged(_new);
    }
    
    /*
     * @dev Function to change the minimal time duration needed between breeder changes. 
     * @dev Can only be called by the contract owner (us)
     * @param uint256 _minTime needed between breeder changes
     */
    function changeMinTime(uint256 _minTime) public onlyOwner {
        minTime = _minTime;
        minTimeChanged(minTime);
    }
    
    /*
     * @dev Function to change address for any UID (new or registered).
     * @dev Can only be called by the contract owner (us) in special cases. 
     * @param bytes32 _uid of the NFC device
     * @param address _address of the UID owner 
     */
    function changeUIDOwner(bytes32 _uid, address _address) public onlyOwner {
        uids[_uid] = _address;
        uidRegistered(_uid, _address);
    }
}

