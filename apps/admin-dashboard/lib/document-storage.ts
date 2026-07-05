export interface StoredDocumentFile {
  fileName: string;
  fileType: string;
  fileSize: number;
  mimeType: string;
  storageUrl: string;
  thumbnail?: string;
  checksum: string;
}
