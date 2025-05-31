export default interface CountResponse {
    responses: ResponseItem[];
  }
  
export  interface ResponseItem {
    fns: number[];
    count: number;
    search_version: number;
}