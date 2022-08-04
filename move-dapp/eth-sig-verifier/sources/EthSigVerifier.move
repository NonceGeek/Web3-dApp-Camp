module MyCounterAddr::EthSigVerifier {
   use StarcoinFramework::Hash;
   use StarcoinFramework::Signature;

   public fun verify_eth_sig(signature: vector<u8>, addr: vector<u8>, message: vector<u8>) : bool{
      // TODO: impl:
      // 0x01) recover pubkey from signature
      // 0x02) generate eth addr from signatue = addr2
      // cond1 = ed25519_verify(signature: vector<u8>, public_key: vector<u8>, message: vector<u8>): bool;
      // cond2 = (addr1 == addr2)
      // cond1 and cond2
   }
}