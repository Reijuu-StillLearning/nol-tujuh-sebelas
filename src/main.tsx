import {MotionConfig} from 'motion/react';
import React from 'react';
import ReactDOM from 'react-dom/client';
import './styles.css';
import './admin.css';
import './cursor.css';
import {birthday} from './data/birthday';
import {Experience} from './components/Experience';
import {Admin} from './components/Admin';
import {configured,loadContent,resolveImages} from './lib/backend';
const hostOk=['localhost','127.0.0.1','::1'].includes(location.hostname);
const localMode=import.meta.env.DEV&&import.meta.env.VITE_DEV_LOCAL_STUDIO==='true'&&hostOk;
function App(){const admin=location.pathname.replace(/\/$/,'')==='/admin';const[content,setContent]=React.useState(birthday);const[warning,setWarning]=React.useState('');React.useEffect(()=>{let active=true;if(configured)void loadContent(false).then(async saved=>{if(saved&&active)setContent(await resolveImages(saved))}).catch(()=>{if(active)setWarning('unavailable')});return()=>{active=false}},[]);if(admin)return <Admin localMode={localMode} onPreview={()=>window.scrollTo({top:0})}/>;return <Experience content={content} loadWarning={warning}/>}
ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><MotionConfig reducedMotion="user"><App/></MotionConfig></React.StrictMode>);
