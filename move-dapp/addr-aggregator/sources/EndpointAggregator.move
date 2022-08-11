module MyAddr::EndpointAggregator {
   use StarcoinFramework::Vector;
   use StarcoinFramework::Signer;

   struct Endpoint has store, copy, drop {
      url: vector<u8>,
      description: vector<u8>
   }

   struct EndpointAggregator has key {
      key_addr: address,
      endpoints: vector<Endpoint>
   }

   public fun create_endpoint_aggregator(acct: &signer){
      let endpoint_aggr =  EndpointAggregator{
         key_addr: Signer::address_of(acct),
         endpoints: Vector::empty<Endpoint>()
      };
      move_to<EndpointAggregator>(acct, endpoint_aggr);
   }

   public fun add_endpoint(
      acct: &signer, 
      url: vector<u8>, 
      description: vector<u8>) acquires EndpointAggregator{
        let endpoint_aggr = borrow_global_mut<EndpointAggregator>(Signer::address_of(acct));
        let endpoint_info = Endpoint{
            url: url, 
            description: description
        };
      Vector::push_back(&mut endpoint_aggr.endpoints, endpoint_info);
   }
   // TODO:
   // public fun update endpoint with description, url
   // public fun delete endpoint
   
}
