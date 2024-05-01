export interface ScApplePayPlugin {

  // initiatePayment(options: { paymentData: string }): void;

  // isWalletHasCards(): Promise<{ value: boolean }>;

  // setupNewCard(): void;

  loadSCPGW(options: { payUrl: string, paymentTitle: string, returnURL: string }): void;
  
}

// export interface PaymentDataInerface {
//   [key: string]: any;
//   summaryItems: { [key: string]: string };
// }

// export class PaymentData implements PaymentDataInerface {
//   private merchantIdentifier: string = '';
//   private countryCode: string = 'QA';
//   private currencyCode: string = 'QAR';
//   private createPaymentLinkEndPoint: string = '';
//   private authorizationHeader: string = '';
//   private firstName: string = '';
//   private lastName: string = '';
//   private amount: string = '';
//   private phone: string = '';
//   private email: string = '';
//   summaryItems: {[key: string]: string} = {};

//   getCurrencyCode(): string{
//     return this.currencyCode;
//   }

//   getCountryCode(): string{
//     return this.countryCode;
//   }

//   setSummaryItem(item: string, amount: string){
//     this.summaryItems[`${item}`] = amount;
//   }

//   getSummaryItem(item: string): any{
//     return this.summaryItems[item];
//   }

//   getAllSummaryItems(): any{
//     return this.summaryItems;
//   }

//   clearSummaryItems(){
//     this.summaryItems = {};
//   }

//   setMerchantIdentifier(mid: string){
//     this.merchantIdentifier = mid;
//   }

//   getMerchantIdentifier(): string{
//     return this.merchantIdentifier;
//   }

//   setPaymentLinkEndPoint(ple: string){
//     this.createPaymentLinkEndPoint = ple;
//   }

//   getPaymentLinkEndPoint(): string{
//     return this.createPaymentLinkEndPoint;
//   }

//   setAuthorizationHeader(authH: string){
//     this.authorizationHeader = authH;
//   }

//   getAuthorizationHeader(): string {
//     return this.authorizationHeader;
//   }

//   setFirstName(fname: string){
//     this.firstName = fname;
//   }

//   getFirstName(): string {
//     return this.firstName;
//   }

//   setLastName(lname: string){
//     this.lastName = lname;
//   }

//   getLastName(): string{
//     return this.lastName;
//   }

//   setAmount(am: string){
//     this.amount = am;
//   }

//   getAmount(): string{
//     return this.amount;
//   }

//   setPhone(p: string){
//     this.phone = p;
//   }

//   getPhone(): string{
//     return this.phone;
//   }

//   setEmail(e: string){
//     this.email = e;
//   }

//   getEmail(): string{
//     return this.email;
//   }


// }