export interface Etablissement {
    name : string,
    email : string,
    phone : string,
    country : string,
    website : string,
}

export interface BodyElement {
    z: string;
    y: string;
    x: string;
}

export interface UniqueResquest {
    endpoint: string;
    body_element: BodyElement;
}

export interface PostObjetDataType {
    endpoint: string; body_element: BodyElement 
}
