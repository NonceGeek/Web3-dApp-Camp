module MyCounterAddr::EthSigVerifier {
   use StarcoinFramework::Hash;
   use StarcoinFramework::Signature;

   public fun verify_eth_sig(signature: vector<u8>, addr: vector<u8>, message: vector<u8>) : bool{
      // TODO: impl:
      // 0x01) recover addr from signature
      // --- ecrecover(hash: vector<u8>, signature: vector<u8>)      // cond2 = (addr1 == addr2)
      // 0x02 addr == ecrecover
   }
}