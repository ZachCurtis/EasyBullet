"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[671],{3905:(e,t,r)=>{r.d(t,{Zo:()=>c,kt:()=>f});var n=r(7294);function a(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function i(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,n)}return r}function l(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?i(Object(r),!0).forEach((function(t){a(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):i(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function o(e,t){if(null==e)return{};var r,n,a=function(e,t){if(null==e)return{};var r,n,a={},i=Object.keys(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||(a[r]=e[r]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(a[r]=e[r])}return a}var s=n.createContext({}),u=function(e){var t=n.useContext(s),r=t;return e&&(r="function"==typeof e?e(t):l(l({},t),e)),r},c=function(e){var t=u(e.components);return n.createElement(s.Provider,{value:t},e.children)},p="mdxType",d={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},y=n.forwardRef((function(e,t){var r=e.components,a=e.mdxType,i=e.originalType,s=e.parentName,c=o(e,["components","mdxType","originalType","parentName"]),p=u(r),y=a,f=p["".concat(s,".").concat(y)]||p[y]||d[y]||i;return r?n.createElement(f,l(l({ref:t},c),{},{components:r})):n.createElement(f,l({ref:t},c))}));function f(e,t){var r=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var i=r.length,l=new Array(i);l[0]=y;var o={};for(var s in t)hasOwnProperty.call(t,s)&&(o[s]=t[s]);o.originalType=e,o[p]="string"==typeof e?e:a,l[1]=o;for(var u=2;u<i;u++)l[u]=r[u];return n.createElement.apply(null,l)}return n.createElement.apply(null,r)}y.displayName="MDXCreateElement"},9881:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>s,contentTitle:()=>l,default:()=>d,frontMatter:()=>i,metadata:()=>o,toc:()=>u});var n=r(7462),a=(r(7294),r(3905));const i={sidebar_position:1,title:"Introduction",sidebar_label:"Introduction"},l="EasyBullet",o={unversionedId:"intro",id:"intro",title:"Introduction",description:"EasyBullet is a simple bullet runtime that handles network replication, network syncing, and adjusts the rendered bullets by client framerate.",source:"@site/docs/intro.md",sourceDirName:".",slug:"/intro",permalink:"/EasyBullet/docs/intro",draft:!1,editUrl:"https://github.com/ZachCurtis/EasyBullet/docs/docs/intro.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{sidebar_position:1,title:"Introduction",sidebar_label:"Introduction"},sidebar:"docsSidebar",next:{title:"Installation",permalink:"/EasyBullet/docs/installation"}},s={},u=[{value:"Features",id:"features",level:2}],c={toc:u},p="wrapper";function d(e){let{components:t,...r}=e;return(0,a.kt)(p,(0,n.Z)({},c,r,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h1",{id:"easybullet"},"EasyBullet"),(0,a.kt)("p",null,"EasyBullet is a simple bullet runtime that handles network replication, network syncing, and adjusts the rendered bullets by client framerate. "),(0,a.kt)("h2",{id:"features"},"Features"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Firing a bullet is as easy as ",(0,a.kt)("inlineCode",{parentName:"li"},"easyBullet:FireBullet(barrelPosition, bulletVelocity)")),(0,a.kt)("li",{parentName:"ul"},"Easily modify EasyBullet's behavior using an extensive settings table"),(0,a.kt)("li",{parentName:"ul"},"Callbacks to override EasyBullet's behavior entirely when the settings table doesn't offer enough"),(0,a.kt)("li",{parentName:"ul"},"Accounts for network latency using client's ping"),(0,a.kt)("li",{parentName:"ul"},"Projectile modeling using kinematic equations")))}d.isMDXComponent=!0}}]);