import type {Content} from '../data/birthday';
const DB='birthday-studio-local-v1',STORE='photos',DRAFT='birthday-studio-draft-v1';
function open():Promise<IDBDatabase>{return new Promise((resolve,reject)=>{const req=indexedDB.open(DB,1);req.onupgradeneeded=()=>req.result.createObjectStore(STORE);req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error)})}
export async function storeLocalPhoto(file:Blob):Promise<string>{const db=await open(),id=crypto.randomUUID();await new Promise<void>((res,rej)=>{const tx=db.transaction(STORE,'readwrite');tx.objectStore(STORE).put(file,id);tx.oncomplete=()=>res();tx.onerror=()=>rej(tx.error)});db.close();return `idb:${id}`}
export async function resolveLocalPhoto(path:string):Promise<string|null>{if(!path.startsWith('idb:'))return path;const db=await open(),id=path.slice(4),blob=await new Promise<Blob|undefined>((res,rej)=>{const r=db.transaction(STORE).objectStore(STORE).get(id);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});db.close();return blob?URL.createObjectURL(blob):null}
export async function removeLocalPhoto(path:string):Promise<void>{if(!path.startsWith('idb:'))return;const db=await open();await new Promise<void>((res,rej)=>{const tx=db.transaction(STORE,'readwrite');tx.objectStore(STORE).delete(path.slice(4));tx.oncomplete=()=>res();tx.onerror=()=>rej(tx.error)});db.close()}
export function saveLocalDraft(data:Content):void{localStorage.setItem(DRAFT,JSON.stringify(data))}
export function loadLocalDraft():Content|null{try{const text=localStorage.getItem(DRAFT);return text?JSON.parse(text) as Content:null}catch{return null}}
export function localDraftKey(){return DRAFT}
